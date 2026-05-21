#!/usr/bin/env python3
"""Diff-preview-then-write rewriter for the §4 Elements column rows in
Tier-1-corrupted wikis. Reads `_tier1_truth_corrections.csv` (and optionally
`_tier1_propagation_map.csv` for cascade targets), edits the matching column
row's description in-place, preserves the `|` table layout exactly, and emits
`audits/_apply_report_<ts>.csv` summarising every edit.

Targets
-------
  --target wikis           : edit the source (DWH_dbo) wikis in `wiki_path`
  --target alter           : regen the matching `.alter.sql` so deployed UC
                             column comments match the corrected wiki text
  --target cascade-synapse : edit BI_DB_dbo + Dealing_dbo + sibling synapse
                             wikis discovered via propagation_map.wiki_inheritance
                             (rewrites their description to the source's
                             corrected text, preserves their tier tag)
  --target cascade-uc      : edit UC_generated/**/*.md downstream consumers
                             discovered via propagation_map.column_lineage
  --target cascade-skills  : patch .cursor/skills + .cursor/rules embeds

By default everything is `--dry-run`. Pass `--apply` to commit edits.
"""
from __future__ import annotations

import argparse
import csv
import difflib
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from tier1_audit.parser import parse_wiki_columns, find_tier1_claims, TIER_TAG_RE

APPLY_REPORT_FIELDS = [
    "correction_id",
    "target",
    "wiki_path",
    "column_name",
    "status",            # applied | skipped_no_change | skipped_no_match | error | dry_run
    "edited_line_no",
    "old_desc",
    "new_desc",
    "notes",
]


@dataclass
class EditPlan:
    correction_id: str
    target: str
    wiki_path: Path
    column_name: str
    old_desc: str
    new_desc: str
    notes: str = ""
    edited_line_no: int = 0


def _norm_col_name(s: str) -> str:
    return (s or "").strip().strip("`").lstrip("[").rstrip("]").lower()


def _find_column_row(wiki_path: Path, column_name: str) -> tuple[int, str, str] | None:
    """Return (line_no, raw_description, raw_line) for the column row, or None."""
    try:
        cols = parse_wiki_columns(wiki_path)
    except Exception:
        return None
    target = _norm_col_name(column_name)
    for c in cols:
        if _norm_col_name(c.column_name) == target:
            text = wiki_path.read_text(encoding="utf-8", errors="replace").splitlines()
            if 1 <= c.line_no <= len(text):
                return c.line_no, c.raw_description, text[c.line_no - 1]
    return None


def _rewrite_description_in_row(
    raw_line: str,
    old_desc: str,
    new_desc: str,
) -> str | None:
    """Replace the description cell (a `|`-delimited cell whose stripped value
    equals `old_desc`) with `new_desc`. Preserves leading/trailing whitespace
    inside the cell. Returns None if the description cell can't be located
    unambiguously."""
    if not raw_line.lstrip().startswith("|"):
        return None
    has_trailing_pipe = raw_line.rstrip().endswith("|")
    nl = ""
    if raw_line.endswith("\n"):
        nl = "\n"
    stripped = raw_line.rstrip("\n").rstrip()
    if stripped.endswith("|"):
        body = stripped[:-1]
    else:
        body = stripped
    cells = body.split("|")
    # cells[0] is empty (leading pipe)
    target = old_desc.strip()
    hits = [i for i, c in enumerate(cells) if c.strip() == target]
    if len(hits) != 1:
        # Fallback: pick the LAST cell that contains the old_desc text exactly
        hits = [i for i, c in enumerate(cells) if c.strip() == target]
        if not hits:
            return None
    idx = hits[-1]
    # Preserve the leading space (most rows are `| <desc> `, trailing space)
    cell_raw = cells[idx]
    lead_ws = len(cell_raw) - len(cell_raw.lstrip())
    trail_ws = len(cell_raw) - len(cell_raw.rstrip())
    cells[idx] = (" " * lead_ws) + new_desc.strip() + (" " * trail_ws)
    rebuilt = "|".join(cells)
    if has_trailing_pipe:
        rebuilt = rebuilt + "|"
    return rebuilt + nl


def _generate_plans_from_corrections(corrections_csv: Path) -> list[EditPlan]:
    plans: list[EditPlan] = []
    with corrections_csv.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            if row.get("conflict_flag", "FALSE").upper() == "TRUE":
                continue
            fix = (row.get("final_proposed_fix") or "").strip()
            if not fix:
                continue
            wp = row.get("wiki_path") or ""
            if not wp:
                continue
            plans.append(EditPlan(
                correction_id=row["correction_id"],
                target="wikis",
                wiki_path=REPO / wp,
                column_name=row["column_name"],
                old_desc=row.get("current_desc", "").strip(),
                new_desc=fix,
                notes="L1-structural" if row.get("new_audit_layer") == "L1-structural"
                      else "L2-semantic" if row.get("new_audit_layer") == "L2-semantic"
                      else "judge-only",
            ))
    return plans


def _generate_plans_for_cascade(
    corrections_csv: Path,
    propagation_csv: Path,
    edge_kind: str,
    target_label: str,
    wiki_filter: callable,
) -> list[EditPlan]:
    """Build edit plans for a cascade target.

    For each propagation_map row whose `edge_kind` matches and whose
    downstream_wiki_path passes `wiki_filter`, look up the source correction's
    `final_proposed_fix` and plan an edit on the downstream wiki's matching
    column row.
    """
    # Map correction_id -> final_proposed_fix + source descriptor
    fix_by_cid: dict[str, dict[str, str]] = {}
    with corrections_csv.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            cid = row["correction_id"]
            fix = (row.get("final_proposed_fix") or "").strip()
            if not fix:
                continue
            if row.get("conflict_flag", "FALSE").upper() == "TRUE":
                continue
            fix_by_cid[cid] = {
                "fix": fix,
                "source_wiki": row.get("wiki_path", ""),
                "source_column": row.get("column_name", ""),
            }

    plans: list[EditPlan] = []
    seen: set[tuple[str, str, str]] = set()
    with propagation_csv.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            if row.get("edge_kind") != edge_kind:
                continue
            if row.get("defer_to_later_layer", "FALSE").upper() == "TRUE":
                continue
            dwp = row.get("downstream_wiki_path") or ""
            if not dwp or not wiki_filter(dwp):
                continue
            cid = row["correction_id"]
            src = fix_by_cid.get(cid)
            if not src:
                continue
            dcol = row.get("downstream_column") or src["source_column"]
            dedup = (dwp.lower(), dcol.lower(), cid)
            if dedup in seen:
                continue
            seen.add(dedup)
            wpath = REPO / dwp
            hit = _find_column_row(wpath, dcol)
            if not hit:
                # Column might not exist (lineage rename) — emit placeholder plan
                plans.append(EditPlan(
                    correction_id=cid,
                    target=target_label,
                    wiki_path=wpath,
                    column_name=dcol,
                    old_desc="",
                    new_desc=src["fix"],
                    notes=f"column not found in {dwp}",
                ))
                continue
            _, old_desc, _ = hit
            plans.append(EditPlan(
                correction_id=cid,
                target=target_label,
                wiki_path=wpath,
                column_name=dcol,
                old_desc=old_desc,
                new_desc=src["fix"],
                notes=f"cascade from {src['source_wiki']}.{src['source_column']}",
            ))
    return plans


def _apply_plans_to_files(
    plans: list[EditPlan],
    *,
    apply: bool,
    interactive: bool,
    diff_limit: int = 30,
) -> list[dict]:
    """Group plans by wiki_path so we make one read+write pass per file."""
    by_file: dict[Path, list[EditPlan]] = {}
    for p in plans:
        by_file.setdefault(p.wiki_path, []).append(p)

    report: list[dict] = []
    files_changed = 0
    files_skipped = 0
    diff_blocks_printed = 0

    for wp, items in sorted(by_file.items(), key=lambda x: str(x[0])):
        if not wp.exists():
            for it in items:
                report.append({
                    "correction_id": it.correction_id,
                    "target": it.target,
                    "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                    "column_name": it.column_name,
                    "status": "skipped_no_match",
                    "edited_line_no": 0,
                    "old_desc": it.old_desc,
                    "new_desc": it.new_desc,
                    "notes": "wiki file not found",
                })
            continue
        original_text = wp.read_text(encoding="utf-8", errors="replace")
        lines = original_text.splitlines(keepends=True)
        edited_lines = list(lines)
        wiki_changed = False
        for it in items:
            hit = _find_column_row(wp, it.column_name)
            if not hit:
                report.append({
                    "correction_id": it.correction_id,
                    "target": it.target,
                    "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                    "column_name": it.column_name,
                    "status": "skipped_no_match",
                    "edited_line_no": 0,
                    "old_desc": it.old_desc,
                    "new_desc": it.new_desc,
                    "notes": "column row not parsed",
                })
                continue
            line_no, raw_desc, _raw_line = hit
            it.edited_line_no = line_no
            line = edited_lines[line_no - 1]
            new_line = _rewrite_description_in_row(line, raw_desc, it.new_desc)
            if new_line is None:
                report.append({
                    "correction_id": it.correction_id,
                    "target": it.target,
                    "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                    "column_name": it.column_name,
                    "status": "skipped_no_match",
                    "edited_line_no": line_no,
                    "old_desc": raw_desc,
                    "new_desc": it.new_desc,
                    "notes": "description cell not uniquely located",
                })
                continue
            if new_line == line:
                report.append({
                    "correction_id": it.correction_id,
                    "target": it.target,
                    "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                    "column_name": it.column_name,
                    "status": "skipped_no_change",
                    "edited_line_no": line_no,
                    "old_desc": raw_desc,
                    "new_desc": it.new_desc,
                    "notes": "new desc identical to current",
                })
                continue
            if interactive:
                print()
                print(f"=== {wp.relative_to(REPO)} line {line_no} col `{it.column_name}` "
                      f"(correction {it.correction_id}) ===")
                for d in difflib.unified_diff([line], [new_line], lineterm=""):
                    print(d)
                ans = input("Apply? [y/N/q] ").strip().lower()
                if ans == "q":
                    print("aborting interactive session")
                    apply = False
                    interactive = False
                elif ans != "y":
                    report.append({
                        "correction_id": it.correction_id,
                        "target": it.target,
                        "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                        "column_name": it.column_name,
                        "status": "skipped_user_no",
                        "edited_line_no": line_no,
                        "old_desc": raw_desc,
                        "new_desc": it.new_desc,
                        "notes": "user declined",
                    })
                    continue
            edited_lines[line_no - 1] = new_line
            wiki_changed = True
            report.append({
                "correction_id": it.correction_id,
                "target": it.target,
                "wiki_path": str(wp.relative_to(REPO)).replace("\\", "/"),
                "column_name": it.column_name,
                "status": "applied" if apply else "dry_run",
                "edited_line_no": line_no,
                "old_desc": raw_desc,
                "new_desc": it.new_desc,
                "notes": it.notes,
            })
        if wiki_changed:
            if apply:
                wp.write_text("".join(edited_lines), encoding="utf-8")
                files_changed += 1
            else:
                if diff_blocks_printed < diff_limit:
                    rel = str(wp.relative_to(REPO)).replace("\\", "/")
                    diff = difflib.unified_diff(
                        lines, edited_lines,
                        fromfile=f"a/{rel}", tofile=f"b/{rel}",
                        lineterm="",
                    )
                    for d in diff:
                        print(d.rstrip("\n"))
                    diff_blocks_printed += 1
                files_changed += 1  # planned
        else:
            files_skipped += 1
    return report


def _write_report(report: list[dict], target: str) -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
    out = REPO / "audits" / f"_apply_report_{target}_{ts}.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=APPLY_REPORT_FIELDS)
        w.writeheader()
        for r in report:
            w.writerow(r)
    return out


# ---- Main entry ----

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--corrections",
                    default=str(REPO / "knowledge" / "_tier1_truth_corrections.csv"))
    ap.add_argument("--propagation",
                    default=str(REPO / "knowledge" / "_tier1_propagation_map.csv"))
    ap.add_argument("--target",
                    choices=("wikis", "alter", "cascade-synapse", "cascade-uc",
                             "cascade-skills"),
                    default="wikis")
    ap.add_argument("--apply", action="store_true",
                    help="Write changes to disk. Default is dry-run (diff only).")
    ap.add_argument("--interactive", action="store_true",
                    help="Prompt y/N per edit (implies --apply for accepted edits)")
    ap.add_argument("--filter-wiki", default="",
                    help="Glob pattern over wiki_path (relative to repo)")
    ap.add_argument("--filter-object", default="",
                    help="Glob pattern over wiki object name (stem)")
    args = ap.parse_args()

    corrections_path = Path(args.corrections)
    propagation_path = Path(args.propagation)

    if args.target == "wikis":
        plans = _generate_plans_from_corrections(corrections_path)
    elif args.target == "cascade-synapse":
        def _is_synapse(wp: str) -> bool:
            return wp.startswith("knowledge/synapse/Wiki/") and not wp.startswith(
                "knowledge/synapse/Wiki/DWH_dbo/")
        plans = _generate_plans_for_cascade(
            corrections_path, propagation_path,
            edge_kind="wiki_inheritance",
            target_label="cascade-synapse",
            wiki_filter=_is_synapse,
        )
    elif args.target == "cascade-uc":
        def _is_uc(wp: str) -> bool:
            return wp.startswith("knowledge/UC_generated/")
        plans = _generate_plans_for_cascade(
            corrections_path, propagation_path,
            edge_kind="column_lineage",
            target_label="cascade-uc",
            wiki_filter=_is_uc,
        )
    elif args.target == "cascade-skills":
        def _is_skill(wp: str) -> bool:
            return wp.startswith(".cursor/skills/") or wp.startswith(".cursor/rules/")
        plans = _generate_plans_for_cascade(
            corrections_path, propagation_path,
            edge_kind="skill_embedded",
            target_label="cascade-skills",
            wiki_filter=_is_skill,
        )
    elif args.target == "alter":
        # Delegate to regen
        from tools.cleanup_tier1.regen_alter import regen_for_corrections
        n = regen_for_corrections(
            corrections_path=corrections_path,
            apply=args.apply,
        )
        print(f"Alter regen: {n} alter files {'updated' if args.apply else 'planned'}.")
        return

    # Apply filters
    import fnmatch
    if args.filter_wiki:
        plans = [p for p in plans if fnmatch.fnmatch(
            str(p.wiki_path.relative_to(REPO)).replace("\\", "/"), args.filter_wiki)]
    if args.filter_object:
        plans = [p for p in plans if fnmatch.fnmatch(p.wiki_path.stem, args.filter_object)]

    if not plans:
        print("No edit plans matched the criteria.")
        return

    print(f"Planned edits: {len(plans)} across {len({p.wiki_path for p in plans})} files. "
          f"Mode: {'APPLY' if args.apply else 'DRY-RUN'}.")
    report = _apply_plans_to_files(
        plans,
        apply=args.apply,
        interactive=args.interactive,
    )
    out = _write_report(report, args.target)
    applied = sum(1 for r in report if r["status"] == "applied")
    drun = sum(1 for r in report if r["status"] == "dry_run")
    skipped = sum(1 for r in report if r["status"].startswith("skipped"))
    print(f"Done. applied={applied} dry_run={drun} skipped={skipped} -> report {out}")


if __name__ == "__main__":
    main()
