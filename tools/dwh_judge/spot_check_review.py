"""Spot-check protocol for the DWH judge review CSV.

Samples N random rows (default 20) from ``knowledge/_dwh_judge_review.csv``
and prints each row with a concrete verification recipe for the human
reviewer. For deterministic rows, it includes the exact Synapse query that
proves the truth_value. For LLM rows, it includes the verbatim
contradicting fact pulled from the prompt's ground-truth blob.

This is a pre-approval safety check: the user runs this BEFORE marking
approve_y_n=Y on many rows, to calibrate confidence in the judge's
precision.

Usage:
    python tools/dwh_judge/spot_check_review.py
    python tools/dwh_judge/spot_check_review.py --n 30 --seed 42
    python tools/dwh_judge/spot_check_review.py --claim-type codepoint
"""
from __future__ import annotations

import argparse
import csv
import random
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REVIEW_CSV = REPO / "knowledge" / "_dwh_judge_review.csv"


def _det_verification(row: dict) -> list[str]:
    """Return concrete steps to manually verify a deterministic row."""
    ct = row["claim_type"]
    obj, col = row["object"], row["column"]
    truth = row["truth_value"]
    out: list[str] = []
    if ct == "type":
        out.append(
            f"SELECT DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, "
            f"NUMERIC_SCALE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='DWH_dbo' "
            f"AND TABLE_NAME='{obj}' AND COLUMN_NAME='{col}'"
        )
    elif ct == "nullable":
        out.append(
            f"SELECT IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS "
            f"WHERE TABLE_SCHEMA='DWH_dbo' AND TABLE_NAME='{obj}' AND COLUMN_NAME='{col}'"
        )
    elif ct == "default":
        out.append(
            f"SELECT COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS "
            f"WHERE TABLE_SCHEMA='DWH_dbo' AND TABLE_NAME='{obj}' AND COLUMN_NAME='{col}'"
        )
    elif ct == "fk_ref":
        out.append(
            f"-- Confirm the referenced object/column exists, e.g.:\n"
            f"-- SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE "
            f"CONCAT(TABLE_NAME,'.',COLUMN_NAME) = '{truth}'"
        )
    elif ct == "codepoint":
        # truth like "4=Internal" -> look up via dictionary cache
        out.append(
            "-- Check live dictionary row:"
        )
        out.append(
            f"-- (consult knowledge/_dictionary_truth.json key={col!r} or run "
            f"the upstream Dim_* lookup against DWH_dbo)"
        )
    elif ct == "lineage_tag":
        out.append("-- Confirm by:")
        out.append(
            f"--   * `Dim_*` -> exists in DWH_dbo?\n"
            f"--   * `SP_*` -> exists in DWH_dbo.sys.sql_modules?\n"
            f"--   * `<Schema>.<Table>` -> exists in production wiki?"
        )
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=20)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--claim-type", default=None,
                    help="Restrict the sample to one claim_type.")
    ap.add_argument("--source", default=None,
                    choices=["deterministic", "llm"],
                    help="Restrict the sample to one verdict_source.")
    args = ap.parse_args()

    if not REVIEW_CSV.exists():
        print(f"ERROR: {REVIEW_CSV.relative_to(REPO)} not found.")
        sys.exit(1)

    rows = list(csv.DictReader(REVIEW_CSV.open(encoding="utf-8")))
    if args.claim_type:
        rows = [r for r in rows if r["claim_type"] == args.claim_type]
    if args.source:
        rows = [r for r in rows if r["verdict_source"] == args.source]
    if not rows:
        print("No rows match the filter; nothing to sample.")
        return

    rnd = random.Random(args.seed)
    n = min(args.n, len(rows))
    sample = rnd.sample(rows, n)

    print(f"Spot-check sample: {n} of {len(rows)} WRONG rows in "
          f"{REVIEW_CSV.relative_to(REPO)}")
    if args.claim_type:
        print(f"Filter: claim_type={args.claim_type}")
    if args.source:
        print(f"Filter: verdict_source={args.source}")
    print()
    print("For each row below, confirm the truth_value against the Synapse")
    print("source listed in truth_source. Verdict the row TRUE_POSITIVE,")
    print("FALSE_POSITIVE, or AMBIGUOUS. Report counts back when done.")
    print()
    print("=" * 78)

    for i, r in enumerate(sample, 1):
        print(f"\n[{i}/{n}]  {r['object']}.{r['column']}  ({r['claim_type']}, "
              f"{r['verdict_source']})")
        print(f"  wiki_file:      {r['wiki_file']}:{r['wiki_line']}")
        print(f"  wiki_value:     {r['wiki_value']!s:.300}")
        print(f"  truth_value:    {r['truth_value']!s:.300}")
        print(f"  truth_source:   {r['truth_source']}")
        if r.get("contradicting_fact_verbatim"):
            print(f"  verbatim_cite:  {r['contradicting_fact_verbatim']!s:.400}")
        if r["verdict_source"] == "deterministic":
            for step in _det_verification(r):
                print(f"  verify:         {step}")
        elif r["verdict_source"] == "llm":
            print(f"  verify:         Confirm contradicting_fact_verbatim is a")
            print(f"                  literal substring of the ground-truth blob")
            print(f"                  for {r['object']}; LLM enforces this but")
            print(f"                  manual eyes catch model paraphrase drift.")
    print("\n" + "=" * 78)
    print(f"\nWhen finished, tally TRUE_POSITIVE / FALSE_POSITIVE / AMBIGUOUS "
          f"and report.")
    print("(Precision = TP / (TP + FP); we target >= 95%.)")


if __name__ == "__main__":
    main()
