"""Audit proposed_fixes.csv files for deploy-time hazards in UC comment text.

Checks for:
  - unescaped pipes (break markdown tables when re-parsed)
  - single quotes (need SQL ' -> '' escape)
  - control chars / newlines (break ALTER statements)
  - length over UC comment limits (1024 hard limit; 500 is our self-imposed safe)
  - leading/trailing whitespace
  - duplicate (wiki, column) keys (would mean two descriptions for one UC column)
  - empty new_description
  - description equals "Direct" (sanity check; rewriter should never emit)
"""
from __future__ import annotations
import csv
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

DEFAULT_FILES = [
    "audits/_desc_quality_apply_v_liabilities/proposed_fixes.csv",
    "audits/_desc_quality_apply_revenue/proposed_fixes.csv",
    "audits/_desc_quality_apply_rest/proposed_fixes.csv",
]

CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")


def main() -> int:
    files = sys.argv[1:] or DEFAULT_FILES
    rows = []
    for f in files:
        p = ROOT / f
        with p.open(encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                r["_src"] = f
                rows.append(r)
    print(f"Total rows: {len(rows)}")
    print("-" * 60)

    issues = {
        "pipe_in_new": 0,
        "single_quote": 0,
        "double_quote": 0,
        "newline_or_cr": 0,
        "control_char": 0,
        "backtick": 0,
        "len_gt_500": 0,
        "len_gt_1000": 0,
        "len_gt_2000": 0,
        "trailing_ws": 0,
        "empty": 0,
        "still_direct": 0,
        "looks_passthrough_only": 0,
    }
    samples = {k: [] for k in issues}
    for r in rows:
        nd = r["new_description"] or ""
        col = r["column"]
        wiki = r["wiki_path"].rsplit("/", 1)[-1]

        if "|" in nd and "\\|" not in nd:
            issues["pipe_in_new"] += 1
            samples["pipe_in_new"].append((wiki, col, nd))
        if "'" in nd:
            issues["single_quote"] += 1
        if '"' in nd:
            issues["double_quote"] += 1
        if "\n" in nd or "\r" in nd:
            issues["newline_or_cr"] += 1
            samples["newline_or_cr"].append((wiki, col, nd[:120]))
        if CTRL_RE.search(nd):
            issues["control_char"] += 1
        if "`" in nd:
            issues["backtick"] += 1
            samples["backtick"].append((wiki, col, nd[:120]))
        L = len(nd)
        if L > 500:
            issues["len_gt_500"] += 1
        if L > 1000:
            issues["len_gt_1000"] += 1
            samples["len_gt_1000"].append((wiki, col, L))
        if L > 2000:
            issues["len_gt_2000"] += 1
        if nd != nd.strip():
            issues["trailing_ws"] += 1
        if not nd.strip():
            issues["empty"] += 1
        if nd.strip().lower() == "direct":
            issues["still_direct"] += 1
            samples["still_direct"].append((wiki, col, nd))

    print("=== Description hygiene ===")
    for k, v in issues.items():
        marker = "" if v == 0 else "  <-- review"
        print(f"  {k:25s}: {v}{marker}")

    print("-" * 60)
    for k, items in samples.items():
        if not items:
            continue
        print(f"Samples [{k}] (first 5 of {len(items)}):")
        for it in items[:5]:
            print(f"  {it}")
        print()

    keys = Counter((r["wiki_path"], r["column"].lower()) for r in rows)
    dups = {k: c for k, c in keys.items() if c > 1}
    print(f"Duplicate (wiki,column) pairs: {len(dups)}")
    for k, c in list(dups.items())[:10]:
        print(f"  {k} x{c}")
    return 0 if all(v == 0 for k, v in issues.items() if k != "single_quote" and k != "len_gt_500") else 1


if __name__ == "__main__":
    raise SystemExit(main())
