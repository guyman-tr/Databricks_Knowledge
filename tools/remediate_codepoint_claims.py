"""
Surgical remediation of codepoint-name MISMATCHes in wiki .alter.sql files.

For each MISMATCH discovered by tools/audit_codepoint_claims.py:
  - Replace the asserted "<N>=<ClaimedLabel>" or "(<N>) <ClaimedLabel>" with
    "<N>=<Tier1TruthName>" (preserving the original syntax form).
  - Skip a few well-known safe cases:
      * "starts-with-truth" claims (regex over-capture; the claim already
        begins with the dictionary name, the rest is trailing prose) -- no
        rewrite, just record as SUPPRESSED.
      * Columns in the SKIP set (currently CurrencyID -- the correct truth
        is Abbreviation, not Name; we'll handle Currency separately).

For each UNKNOWN_CODEPOINT discovered:
  - Annotate the asserted "<N>=<Label>" by replacing it with
    "<N>=<Label> [UNVERIFIED: codepoint not in DWH_dbo.<Dim>]"
  - The bot can't decide what to do with a non-dictionary codepoint -- the
    annotation flags it for human review.

What this tool does NOT do
--------------------------
  - It does not deploy anything to UC. It writes:
        knowledge/_codepoint_claims_remediation.alter.sql  (deployable)
        knowledge/_codepoint_claims_remediation_preview.csv (per-change preview)
    Optionally with --apply it also rewrites the wiki source .alter.sql files
    in place.

Usage
-----
  python tools/remediate_codepoint_claims.py                  # dry-run preview only
  python tools/remediate_codepoint_claims.py --apply          # patch wiki sources
  python tools/remediate_codepoint_claims.py --apply --no-sql # patch sources, skip SQL emit
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
AUDIT_CSV = REPO / "knowledge" / "_codepoint_claims_audit.csv"
TRUTH_JSON = REPO / "knowledge" / "_dictionary_truth.json"
PREVIEW_CSV = REPO / "knowledge" / "_codepoint_claims_remediation_preview.csv"
REMEDIATION_SQL = REPO / "knowledge" / "_codepoint_claims_remediation.alter.sql"

# Columns to skip wholesale in this pass.
SKIP_COLUMNS = {"CurrencyID"}  # truth-column mismatch (use Abbreviation, not Name)

# Phrases that indicate a column is NOT a true FK to Dim_<X>; it's been
# repurposed for a different local enum in this specific table. Surgical
# replacement against the Dim_<X> truth would CORRUPT these comments.
REPURPOSED_HINTS = (
    "derived via",
    "derived from",
    "renamed from",
    "renamed to",
    "passthrough",
    "pass-through",
    "case when",
    "case on",
    "computed as",
    "computed from",
    "not fk",
    "local enum",
    "not a true fk",
)

VERIFIED_DATE = "2026-05-13"

COMMENT_STMT = re.compile(
    r"(?P<head>ALTER (?:TABLE|VIEW)\s+(?P<uc>[\w.]+)\s+ALTER COLUMN\s+`?(?P<col>\w+)`?\s+COMMENT\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;?)",
    re.IGNORECASE,
)
COMMENT_ON_STMT = re.compile(
    r"(?P<head>COMMENT\s+ON\s+COLUMN\s+(?P<uc>[\w.`]+)\.`?(?P<col>\w+)`?\s+IS\s+')"
    r"(?P<body>(?:[^']|'')*)"
    r"(?P<tail>'\s*;?)",
    re.IGNORECASE,
)


@dataclass
class Change:
    file_relpath: str
    line: int
    uc_object: str
    column: str
    codepoint: str
    claimed_label: str
    truth_name: str
    action: str            # REPLACE / ANNOTATE / SUPPRESS
    rationale: str = ""


@dataclass
class StatementPlan:
    file: Path
    pos_start: int
    pos_end: int
    head: str
    body: str
    tail: str
    uc_object: str
    column: str
    changes: list[Change] = field(default_factory=list)


def _normalize(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[\s\-_/+]+", " ", s)
    s = re.sub(r"[^a-z0-9 ]", "", s)
    return s.strip()


def _find_line(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def _replace_assertion(body: str, codepoint: str, claimed_label: str,
                       new_label: str) -> tuple[str, bool]:
    """Replace either '<N>=<ClaimedLabel>' or '(<N>) <ClaimedLabel>' inside body.
    Returns (new_body, replaced?)."""
    # Try '=' form first
    target_eq = f"{codepoint}={claimed_label}"
    target_eq_space = f"{codepoint} = {claimed_label}"
    target_paren = f"({codepoint}) {claimed_label}"
    for target in (target_eq, target_eq_space, target_paren):
        if target in body:
            if target == target_paren:
                replacement = f"({codepoint}) {new_label}"
            elif target == target_eq_space:
                replacement = f"{codepoint} = {new_label}"
            else:
                replacement = f"{codepoint}={new_label}"
            return body.replace(target, replacement, 1), True
    return body, False


def _annotate_unknown(body: str, codepoint: str, claimed_label: str,
                      dim: str) -> tuple[str, bool]:
    """Suffix an asserted '<N>=<Label>' with [UNVERIFIED: codepoint not in <dim>].
    Skip if a UNVERIFIED tag already appears within ~80 chars after the target
    (legacy from a prior audit pass) -- avoids duplicate annotations."""
    note = f" [UNVERIFIED: codepoint not in {dim}]"
    target_eq = f"{codepoint}={claimed_label}"
    target_eq_space = f"{codepoint} = {claimed_label}"
    target_paren = f"({codepoint}) {claimed_label}"
    for target in (target_eq, target_eq_space, target_paren):
        idx = body.find(target)
        if idx < 0:
            continue
        tail = body[idx + len(target): idx + len(target) + 80]
        if "[UNVERIFIED:" in tail:
            # already annotated nearby by a prior pass; skip
            return body, False
        return body.replace(target, target + note, 1), True
    return body, False


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true",
                    help="Rewrite wiki source .alter.sql files in place "
                         "(default: dry-run, no source edits).")
    ap.add_argument("--no-sql", action="store_true",
                    help="Skip writing the standalone remediation .alter.sql.")
    args = ap.parse_args()

    if not AUDIT_CSV.is_file():
        raise SystemExit(f"Missing {AUDIT_CSV}. Run audit_codepoint_claims.py first.")
    if not TRUTH_JSON.is_file():
        raise SystemExit(f"Missing {TRUTH_JSON}. Run fetch_dictionary_truth.py first.")

    truth = json.loads(TRUTH_JSON.read_text(encoding="utf-8"))

    # Group audit rows by (file, line, uc, column) so we apply all changes to a
    # statement in one pass. We carry forward the per-row dictionary_table so
    # ANNOTATE messages cite the correct schema-specific dim.
    by_stmt: dict[tuple[str, int, str, str], list[dict]] = defaultdict(list)
    with AUDIT_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["verdict"] not in ("MISMATCH", "UNKNOWN_CODEPOINT"):
                continue
            if r["column"] in SKIP_COLUMNS:
                continue
            by_stmt[(r["file_relpath"], int(r["line"]), r["uc_object"], r["column"])].append(r)

    # For each unique file, collect all statement plans.
    file_plans: dict[Path, list[StatementPlan]] = defaultdict(list)

    all_changes: list[Change] = []

    for (rel, line, uc, col), rows in by_stmt.items():
        path = REPO / rel
        text = path.read_text(encoding="utf-8")
        # Find the COMMENT statement that contains this `line`. We re-scan the
        # file and pick the statement whose head starts at the matching line.
        found = None
        for pat in (COMMENT_STMT, COMMENT_ON_STMT):
            for m in pat.finditer(text):
                start_line = _find_line(text, m.start())
                if start_line != line:
                    continue
                m_uc = m.group("uc")
                m_col = m.group("col")
                # COMMENT_ON_STMT uc has trailing column suffix already split by regex
                if m_uc.replace("`", "") == uc.replace("`", "") and m_col == col:
                    found = m
                    break
            if found is not None:
                break
        if found is None:
            for r in rows:
                all_changes.append(Change(
                    file_relpath=rel, line=line, uc_object=uc, column=col,
                    codepoint=r["codepoint"], claimed_label=r["claimed_label"],
                    truth_name=r["tier1_truth_name"], action="SKIPPED_NO_MATCH",
                    rationale="Could not locate statement in file (regex re-match failed)",
                ))
            continue

        body = found.group("body").replace("''", "'")
        head = found.group("head")
        tail = found.group("tail")
        original_body = body

        # Repurposed-column guard: if the comment body advertises the column
        # as a derived / passthrough / CASE-computed local value, the Tier-1
        # truth doesn't apply. Suppress all changes for this statement.
        body_lc = body.lower()
        if any(h in body_lc for h in REPURPOSED_HINTS):
            for r in rows:
                all_changes.append(Change(
                    file_relpath=rel, line=line, uc_object=uc, column=col,
                    codepoint=r["codepoint"], claimed_label=r["claimed_label"],
                    truth_name=r["tier1_truth_name"], action="SUPPRESSED",
                    rationale="Column is repurposed in this table "
                              "(comment body advertises derived/passthrough/CASE source).",
                ))
            continue

        for r in rows:
            codepoint = r["codepoint"]
            claimed = r["claimed_label"]
            truth_name = r["tier1_truth_name"]
            verdict = r["verdict"]
            dim = r.get("dictionary_table") or (truth.get(col) or {}).get("dim") or ""

            # Guard 1: starts-with-truth -- the regex over-captured prose.
            if verdict == "MISMATCH" and truth_name and \
                    _normalize(claimed).startswith(_normalize(truth_name) + " ") \
                    or _normalize(claimed) == _normalize(truth_name):
                all_changes.append(Change(
                    file_relpath=rel, line=line, uc_object=uc, column=col,
                    codepoint=codepoint, claimed_label=claimed,
                    truth_name=truth_name, action="SUPPRESSED",
                    rationale="Claim starts with truth; regex over-captured trailing prose.",
                ))
                continue

            if verdict == "MISMATCH":
                new_body, ok = _replace_assertion(body, codepoint, claimed, truth_name)
                if ok:
                    body = new_body
                    all_changes.append(Change(
                        file_relpath=rel, line=line, uc_object=uc, column=col,
                        codepoint=codepoint, claimed_label=claimed,
                        truth_name=truth_name, action="REPLACE",
                    ))
                else:
                    all_changes.append(Change(
                        file_relpath=rel, line=line, uc_object=uc, column=col,
                        codepoint=codepoint, claimed_label=claimed,
                        truth_name=truth_name, action="SKIPPED_NO_TEXT_MATCH",
                        rationale="Exact assertion substring not found "
                                  "(comment may have unusual formatting).",
                    ))
            elif verdict == "UNKNOWN_CODEPOINT":
                new_body, ok = _annotate_unknown(body, codepoint, claimed, dim)
                if ok:
                    body = new_body
                    all_changes.append(Change(
                        file_relpath=rel, line=line, uc_object=uc, column=col,
                        codepoint=codepoint, claimed_label=claimed,
                        truth_name="", action="ANNOTATE",
                        rationale=f"Codepoint not in {dim}",
                    ))
                else:
                    all_changes.append(Change(
                        file_relpath=rel, line=line, uc_object=uc, column=col,
                        codepoint=codepoint, claimed_label=claimed,
                        truth_name="", action="SKIPPED_NO_TEXT_MATCH",
                        rationale="Exact assertion substring not found.",
                    ))

        if body != original_body:
            file_plans[path].append(StatementPlan(
                file=path,
                pos_start=found.start(),
                pos_end=found.end(),
                head=head,
                body=body,
                tail=tail,
                uc_object=uc,
                column=col,
            ))

    # Write preview CSV
    PREVIEW_CSV.parent.mkdir(parents=True, exist_ok=True)
    with PREVIEW_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "file_relpath", "line", "uc_object", "column", "codepoint",
            "claimed_label", "truth_name", "action", "rationale",
        ])
        for c in all_changes:
            w.writerow([
                c.file_relpath, c.line, c.uc_object, c.column, c.codepoint,
                c.claimed_label, c.truth_name, c.action, c.rationale,
            ])
    print(f"Wrote preview: {PREVIEW_CSV.relative_to(REPO)}", flush=True)

    # Summary
    action_counts: dict[str, int] = defaultdict(int)
    for c in all_changes:
        action_counts[c.action] += 1
    print("Action counts:")
    for a, n in sorted(action_counts.items(), key=lambda kv: -kv[1]):
        print(f"  {a:<24} {n}")

    # Emit remediation .alter.sql -- one corrected statement per file_plans entry.
    if not args.no_sql:
        lines: list[str] = []
        lines.append(
            "-- =============================================================================\n"
            "-- Codepoint-name remediation -- Tier-1 vs Tier > 1 judge\n"
            "-- Generated by tools/remediate_codepoint_claims.py\n"
            "-- Truth source: knowledge/_dictionary_truth.json (live DWH_dbo.Dim_* tables).\n"
            f"-- Verified: {VERIFIED_DATE}\n"
            "-- =============================================================================\n"
        )
        seen_uc_col: set[tuple[str, str]] = set()
        for path, plans in sorted(file_plans.items(), key=lambda kv: str(kv[0])):
            for p in plans:
                key = (p.uc_object.replace("`", "").lower(), p.column.lower())
                if key in seen_uc_col:
                    continue
                seen_uc_col.add(key)
                escaped = p.body.replace("'", "''")
                stmt = p.head + escaped + p.tail
                if not stmt.rstrip().endswith(";"):
                    stmt = stmt.rstrip() + ";"
                lines.append(stmt)
        REMEDIATION_SQL.parent.mkdir(parents=True, exist_ok=True)
        REMEDIATION_SQL.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"Wrote remediation SQL: {REMEDIATION_SQL.relative_to(REPO)} "
              f"({len(seen_uc_col)} statements)")

    if args.apply:
        # Rewrite each wiki source file in place. Apply plans in reverse position
        # order so offsets remain valid.
        for path, plans in file_plans.items():
            text = path.read_text(encoding="utf-8")
            plans_sorted = sorted(plans, key=lambda p: -p.pos_start)
            for p in plans_sorted:
                escaped = p.body.replace("'", "''")
                new_stmt = p.head + escaped + p.tail
                text = text[:p.pos_start] + new_stmt + text[p.pos_end:]
            path.write_text(text, encoding="utf-8")
        print(f"Patched {len(file_plans)} wiki files in place.")
    else:
        print("\n[dry-run] Wiki source files NOT modified. "
              "Re-run with --apply to patch them, then deploy the remediation SQL.")


if __name__ == "__main__":
    main()
