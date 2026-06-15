"""
Rewrite TRIVIAL §4 rows in a wiki by climbing the upstream chain.

Usage:
    # Dry run (default): print diff + write proposed_fixes.csv
    python tools/desc_quality/rewrite.py --wiki knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md

    # Apply to disk (only after reviewing the dry-run diff!)
    python tools/desc_quality/rewrite.py --wiki ... --apply

    # Batch (many wikis)
    python tools/desc_quality/rewrite.py --glob "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_*.md" --out audits/_desc_quality_rewrite_revenue/

Outputs (per run):
    {out}/report.csv           - one row per (wiki, column) touched, with old/new and status
    {out}/proposed_fixes.csv   - same shape as tools/cleanup_tier1/apply_column_fixes.py
                                 (compatible with the existing review CLI)
    {out}/diff.patch           - unified diff of all proposed edits (dry-run only)
"""
from __future__ import annotations

import argparse
import csv
import difflib
import re
import sys
from dataclasses import dataclass
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.desc_quality.classify import Verdict, classify  # noqa: E402
from tools.desc_quality.upstream_climber import (  # noqa: E402
    ClimbResult,
    climb_upstream,
    format_terminal_cell,
)
from tools.desc_quality.wiki_parse import (  # noqa: E402
    ParsedRow,
    ParsedTable,
    parse_wiki,
)


# Pattern to extract a bookkeeping parenthetical at the END of a Direct cell:
#   "Direct (alias DateKey → DateID)"  -> "alias DateKey → DateID"
#   "Direct (legacy — always 0 since 2019)" -> "legacy — always 0 since 2019"
_BOOKKEEPING_PAREN_RE = re.compile(r"^\s*Direct\s*\(\s*(?P<paren>.+?)\s*\)\s*$", re.IGNORECASE)


@dataclass
class RewritePlan:
    wiki_path: Path
    row: ParsedRow
    old_cell: str
    new_cell: str
    climb: ClimbResult
    status: str  # FOUND / EXHAUSTED
    semantic_col_idx: int


def _extract_preserve_parens(cell: str) -> str:
    m = _BOOKKEEPING_PAREN_RE.match(cell)
    if not m:
        return ""
    return m.group("paren")


def _replace_cell_in_row(raw_row: str, col_idx: int, new_cell: str) -> str:
    """Rebuild a markdown table row, replacing the cell at index `col_idx`.

    `col_idx` is the index after dropping leading/trailing empty cells from the
    pipe split, matching what wiki_parse._split_table_row returns.
    """
    # Find the leading and trailing whitespace + first/last pipe to preserve.
    # Approach: split by '|', track which segments are content (not the leading/
    # trailing wrappers).
    parts = raw_row.split("|")
    # Markdown rows look like: "| a | b | c |" -> ['', ' a ', ' b ', ' c ', '']
    # Walk content cells (skip first/last empty segments).
    content_indices: list[int] = []
    for i, p in enumerate(parts):
        if i == 0 and p.strip() == "":
            continue
        if i == len(parts) - 1 and p.strip() == "":
            continue
        content_indices.append(i)

    if col_idx >= len(content_indices):
        return raw_row  # bail safely

    target = content_indices[col_idx]
    # Preserve the surrounding single space around the value (markdown convention).
    parts[target] = f" {new_cell} "
    return "|".join(parts)


def build_plans(wiki_path: Path) -> tuple[ParsedTable, list[RewritePlan]]:
    tbl = parse_wiki(wiki_path)
    if not tbl.rows or tbl.semantic_header_used is None:
        return tbl, []
    semantic_col_idx = tbl.headers.index(tbl.semantic_header_used)

    plans: list[RewritePlan] = []
    obj_name = wiki_path.stem
    for row in tbl.rows:
        verdict, _ = classify(row.semantic_cell)
        if verdict != Verdict.TRIVIAL:
            continue
        if not tbl.has_source_column:
            # Cannot climb without a Source column. Mark visibly.
            cr = ClimbResult(start_object=obj_name, start_column=row.column)
            cr.exhausted = True
            cr.exhausted_reason = "no_source_column_on_self"
            new_cell = format_terminal_cell(cr)
            plans.append(
                RewritePlan(
                    wiki_path=wiki_path,
                    row=row,
                    old_cell=row.semantic_cell,
                    new_cell=new_cell,
                    climb=cr,
                    status="EXHAUSTED",
                    semantic_col_idx=semantic_col_idx,
                )
            )
            continue

        cr = climb_upstream(obj_name, row.column)
        preserve = _extract_preserve_parens(row.semantic_cell)
        new_cell = format_terminal_cell(cr, preserve_parens=preserve)
        status = "FOUND" if cr.terminal_text else "EXHAUSTED"
        plans.append(
            RewritePlan(
                wiki_path=wiki_path,
                row=row,
                old_cell=row.semantic_cell,
                new_cell=new_cell,
                climb=cr,
                status=status,
                semantic_col_idx=semantic_col_idx,
            )
        )
    return tbl, plans


def apply_to_text(text: str, plans: list[RewritePlan]) -> tuple[str, int, list[str]]:
    """Apply rewrite plans to a wiki's text. Returns (new_text, applied_count, errors)."""
    new_text = text
    errors: list[str] = []
    applied = 0
    for p in plans:
        old_row = p.row.raw_row_text
        new_row = _replace_cell_in_row(old_row, p.semantic_col_idx, p.new_cell)
        if new_row == old_row:
            errors.append(f"#{p.row.idx} {p.row.column}: no change after replace")
            continue
        if old_row not in new_text:
            errors.append(f"#{p.row.idx} {p.row.column}: original row not found in file")
            continue
        # Make sure we only replace once (uniqueness check)
        if new_text.count(old_row) > 1:
            errors.append(f"#{p.row.idx} {p.row.column}: original row appears more than once")
            continue
        new_text = new_text.replace(old_row, new_row, 1)
        applied += 1
    return new_text, applied, errors


def write_outputs(out_dir: Path, wiki_text_pairs: list[tuple[Path, str, str]], all_plans: list[RewritePlan]) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    # report.csv: one row per plan
    with (out_dir / "report.csv").open("w", newline="", encoding="utf-8") as fcsv:
        w = csv.writer(fcsv)
        w.writerow(
            [
                "wiki_path",
                "idx",
                "column",
                "source",
                "old_cell",
                "new_cell",
                "status",
                "hops",
                "terminal_object",
                "exhausted_reason",
            ]
        )
        for p in all_plans:
            w.writerow(
                [
                    str(p.wiki_path.relative_to(_REPO_ROOT)).replace("\\", "/"),
                    p.row.idx,
                    p.row.column,
                    p.row.source,
                    p.old_cell,
                    p.new_cell,
                    p.status,
                    len(p.climb.hops),
                    p.climb.terminal_object or "",
                    p.climb.exhausted_reason or "",
                ]
            )

    # proposed_fixes.csv: mirrors the shape used by tools/cleanup_tier1/apply_column_fixes.py
    # so the existing review CLI can be reused.
    with (out_dir / "proposed_fixes.csv").open("w", newline="", encoding="utf-8") as fcsv:
        w = csv.writer(fcsv)
        w.writerow(["wiki_path", "column", "old_description", "new_description", "reason"])
        for p in all_plans:
            reason = (
                f"climb_found:{p.climb.terminal_object}"
                if p.status == "FOUND"
                else f"climb_exhausted:{p.climb.exhausted_reason}"
            )
            w.writerow(
                [
                    str(p.wiki_path.relative_to(_REPO_ROOT)).replace("\\", "/"),
                    p.row.column,
                    p.old_cell,
                    p.new_cell,
                    reason,
                ]
            )

    # diff.patch: one unified diff for every wiki touched
    with (out_dir / "diff.patch").open("w", encoding="utf-8") as fdiff:
        for wpath, before, after in wiki_text_pairs:
            rel = str(wpath.relative_to(_REPO_ROOT)).replace("\\", "/")
            diff = difflib.unified_diff(
                before.splitlines(keepends=True),
                after.splitlines(keepends=True),
                fromfile=f"a/{rel}",
                tofile=f"b/{rel}",
                n=2,
            )
            fdiff.writelines(diff)


def main() -> int:
    ap = argparse.ArgumentParser(description="Rewrite trivial §4 rows via upstream climb")
    ap.add_argument("--wiki", nargs="*")
    ap.add_argument("--glob")
    ap.add_argument("--out", default="audits/_desc_quality_rewrite")
    ap.add_argument("--apply", action="store_true", help="Write changes to disk")
    ap.add_argument(
        "--include-exhausted",
        action="store_true",
        help="Also emit Passthrough tags for exhausted climbs (default: skip them)",
    )
    args = ap.parse_args()

    if not args.wiki and not args.glob:
        print("Specify --wiki or --glob", file=sys.stderr)
        return 2

    if args.wiki:
        wikis = [Path(p).resolve() for p in args.wiki]
    else:
        wikis = sorted(_REPO_ROOT.glob(args.glob))

    out_dir = (_REPO_ROOT / args.out).resolve()

    all_plans: list[RewritePlan] = []
    wiki_text_pairs: list[tuple[Path, str, str]] = []
    total_found = total_exhausted = 0
    apply_errors: list[str] = []

    for wp in wikis:
        if not wp.exists():
            print(f"Skip (missing): {wp}", file=sys.stderr)
            continue
        tbl, plans = build_plans(wp)
        if not plans:
            continue
        # Optionally filter out EXHAUSTED plans (the rewriter still produces them
        # in the report so we can see what's not climbable; --include-exhausted
        # decides whether the file edit applies them).
        plans_to_apply = (
            plans if args.include_exhausted else [p for p in plans if p.status == "FOUND"]
        )
        original_text = wp.read_text(encoding="utf-8")
        new_text, applied, errs = apply_to_text(original_text, plans_to_apply)
        for e in errs:
            apply_errors.append(f"{wp.name}: {e}")
        all_plans.extend(plans)
        total_found += sum(1 for p in plans if p.status == "FOUND")
        total_exhausted += sum(1 for p in plans if p.status == "EXHAUSTED")
        if new_text != original_text:
            wiki_text_pairs.append((wp, original_text, new_text))
            if args.apply:
                wp.write_text(new_text, encoding="utf-8")
                print(f"  applied {applied} edits -> {wp.relative_to(_REPO_ROOT)}")
            else:
                print(f"  proposed {applied} edits in {wp.relative_to(_REPO_ROOT)}")

    write_outputs(out_dir, wiki_text_pairs, all_plans)

    print()
    print(f"Wikis examined: {len(wikis)}")
    print(f"Wikis with proposed edits: {len(wiki_text_pairs)}")
    print(f"Trivial rows: {len(all_plans)}  (FOUND: {total_found}  EXHAUSTED: {total_exhausted})")
    print(f"Output: {out_dir}")
    if apply_errors:
        print(f"\nApply errors ({len(apply_errors)}):")
        for e in apply_errors[:10]:
            print(f"  {e}")
        if len(apply_errors) > 10:
            print(f"  ... and {len(apply_errors) - 10} more")
    if not args.apply:
        print("\n(dry run — no files modified; re-run with --apply to commit)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
