"""Apply user-approved decisions from `_dict_ref_audit_review.csv` to wiki .md.

For each row whose `decision` is APPROVE or MODIFY:
  - APPROVE: replace the description cell of every affected Elements row
    with `suggested_replacement`.
  - MODIFY: replace with `override_text` (if non-empty), else fall back to
    `suggested_replacement`.
  - SKIP / blank: leave the row alone.

This script is idempotent within a run: it reads each affected .md once,
patches all rows in memory, then writes the .md back. A per-edit trace is
written to `knowledge/_dict_ref_audit_apply_report.csv`.

Hard rules enforced:
  - Only the description cell of the target row is changed. Column name,
    type cell, and nullable cell are left untouched.
  - The Elements section boundary is honoured: edits outside Elements are
    refused (sanity guard, in case `line_no` is stale).

DRY-RUN by default. Pass `--apply` to actually write files.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(REPO / "tools"))
from merge_wiki_column_comments_into_alter import (  # type: ignore
    _ELEMENTS_HEADER_RE,
    _NEXT_TOP_SECTION_RE,
)


def _elements_line_range(text: str) -> tuple[int, int] | None:
    m = _ELEMENTS_HEADER_RE.search(text)
    if not m:
        return None
    start_offset = m.end()
    nxt = _NEXT_TOP_SECTION_RE.search(text[start_offset:])
    end_offset = start_offset + nxt.start() if nxt else len(text)
    start_line = text[:start_offset].count("\n")
    end_line = text[:end_offset].count("\n")
    return start_line + 1, end_line + 1  # 1-indexed inclusive


def rewrite_description_cell(line: str, column_name: str, new_desc: str) -> tuple[str, str]:
    """Return (rewritten_line, status). Replace the last (description) cell
    in a markdown table row, but only if column_name appears as one of the
    leading cells (safety check)."""
    if not line.lstrip().startswith("|"):
        return line, "FAIL_NOT_TABLE_ROW"
    # Split on pipe, preserving leading/trailing empties from the leading/trailing |
    parts = line.split("|")
    # Find column name cell (must be in the leading half)
    found_col = False
    for i, cell in enumerate(parts):
        cand = cell.strip().strip("`")
        if cand.startswith("[") and cand.endswith("]"):
            cand = cand[1:-1].strip()
        if cand == column_name:
            found_col = True
            break
    if not found_col:
        return line, "FAIL_COL_NOT_IN_ROW"
    # Replace the last non-empty cell (description) with new_desc
    if len(parts) < 3:
        return line, "FAIL_TOO_FEW_CELLS"
    # parts[-1] is usually empty (after trailing |). The description cell is
    # the last non-empty cell.
    desc_idx = len(parts) - 1
    while desc_idx >= 0 and parts[desc_idx].strip() == "":
        desc_idx -= 1
    if desc_idx <= 0:
        return line, "FAIL_NO_DESC_CELL"
    parts[desc_idx] = f" {new_desc} "
    return "|".join(parts), "OK"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                         help="Actually write files (default: dry-run).")
    parser.add_argument("--review-csv", default="knowledge/_dict_ref_audit_review.csv")
    parser.add_argument("--report-csv", default="knowledge/_dict_ref_audit_apply_report.csv")
    args = parser.parse_args()

    review_csv = REPO / args.review_csv
    report_csv = REPO / args.report_csv

    rows = list(csv.DictReader(review_csv.open(encoding="utf-8")))
    approved = [r for r in rows
                if r["decision"].strip().upper() in ("APPROVE", "MODIFY")]

    skipped = [r for r in rows
               if r["decision"].strip().upper() in ("SKIP", "")]

    print(f"Approved/Modified decisions: {len(approved)}")
    print(f"Skipped/blank decisions:     {len(skipped)}")
    if not approved:
        print("\nNo APPROVE or MODIFY decisions found - nothing to apply.")
        return 0

    # Group target edits by md path. Each edit identifies the column_name and
    # the replacement text; line_no is a sanity-anchor.
    edits_by_md: dict[str, list[dict]] = defaultdict(list)
    n_targets = 0
    for r in approved:
        decision = r["decision"].strip().upper()
        replacement = (r["override_text"].strip()
                       if decision == "MODIFY" and r["override_text"].strip()
                       else r["suggested_replacement"])
        try:
            targets = json.loads(r["affected_targets_json"])
        except (ValueError, KeyError):
            targets = []
        for t in targets:
            edits_by_md[t["wiki_md"]].append({
                "decision_id": r["decision_id"],
                "column_name": r["column_name"],
                "line_no": int(t["line_no"]),
                "new_desc": replacement,
            })
            n_targets += 1
    print(f"Total wiki rows to edit:     {n_targets}")
    print(f"Distinct wiki files:         {len(edits_by_md)}")

    report = []
    for md_rel, edits in sorted(edits_by_md.items()):
        md_path = REPO / md_rel
        if not md_path.exists():
            for e in edits:
                report.append({**e, "wiki_md": md_rel, "status": "FAIL_MD_NOT_FOUND"})
            continue
        text = md_path.read_text(encoding="utf-8")
        lines = text.splitlines(keepends=True)
        elem_span = _elements_line_range(text)

        # Apply edits in DESCENDING line_no order so we don't have to worry
        # about line drift (no line additions/deletions, only replacements,
        # but defensive).
        edits_sorted = sorted(edits, key=lambda e: -e["line_no"])
        for e in edits_sorted:
            line_no = e["line_no"]
            line_idx = line_no - 1
            if elem_span and not (elem_span[0] <= line_no <= elem_span[1]):
                report.append({**e, "wiki_md": md_rel, "status": "FAIL_OUTSIDE_ELEMENTS"})
                continue
            if not (0 <= line_idx < len(lines)):
                report.append({**e, "wiki_md": md_rel, "status": "FAIL_LINE_OOB"})
                continue
            old_line = lines[line_idx]
            trailing_nl = "\n" if old_line.endswith("\n") else ""
            new_body, status = rewrite_description_cell(
                old_line.rstrip("\n"), e["column_name"], e["new_desc"])
            if status == "OK":
                lines[line_idx] = new_body + trailing_nl
            report.append({**e, "wiki_md": md_rel, "status": status})

        if args.apply:
            md_path.write_text("".join(lines), encoding="utf-8")

    n_ok = sum(1 for r in report if r["status"] == "OK")
    n_fail = sum(1 for r in report if r["status"] != "OK")
    with report_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "decision_id", "wiki_md", "line_no", "column_name", "new_desc", "status",
        ])
        w.writeheader()
        for r in report:
            w.writerow(r)

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"\n[{mode}] Wrote {report_csv.relative_to(REPO).as_posix()}: "
          f"{n_ok} OK, {n_fail} failures")
    if n_fail:
        print("\nFailure breakdown:")
        from collections import Counter
        fails = Counter(r["status"] for r in report if r["status"] != "OK")
        for s, n in fails.most_common():
            print(f"  {n:>4}  {s}")

    if args.apply:
        print("\nNext steps:")
        print("  1. python tools/regen_alter_from_wiki.py <affected .md paths>")
        print("  2. python tools/redeploy_schema.py --schemas <schemas> --label dict_ref_audit --apply")
        print("  3. For VIEW targets, route through tools/_tmp_deploy_view_comments.py")
    else:
        print("\nDRY-RUN only - rerun with --apply to actually modify files.")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
