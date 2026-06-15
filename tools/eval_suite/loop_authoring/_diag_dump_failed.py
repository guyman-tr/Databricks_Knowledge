"""Dump every failed case (passed != true) with full context."""
from __future__ import annotations

import csv
import sys


def main(csv_path: str) -> int:
    rows = list(csv.DictReader(open(csv_path, "r", encoding="utf-8")))
    for r in rows:
        if (r.get("passed") or "").lower() == "true":
            continue
        print("=" * 90)
        print(f"CASE: {r['case_id']}")
        print(f"NLQ:  {r['natural_language_question']}")
        print(f"\nexpected = {r['expected_value']}    observed = {r['observed_value']}")
        print(f"diff_abs = {r['diff_abs']}    diff_pct = {r['diff_pct']}")
        print(f"reason   = {r.get('reason')}")
        if r.get("sut_error"):
            err = r["sut_error"]
            print(f"\nERROR: {err[:600]}")
        if r.get("baseline_value"):
            print(f"baseline_value = {r['baseline_value']}    "
                  f"baseline_passed = {r['baseline_passed']}")
        print("\nLLM SQL:")
        print(r.get("sql_used") or "(none)")
        print("\ntext_answer:", (r.get("sut_text_answer") or "")[:300])
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1
                  else "audits/eval_suite/runs/run-20260614T125117Z.csv"))
