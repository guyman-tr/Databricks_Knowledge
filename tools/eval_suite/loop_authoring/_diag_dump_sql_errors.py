"""Dump the actual SQL error message + the LLM-emitted SQL for each failed case."""
from __future__ import annotations

import csv
import re
import sys


def _extract_msg(err: str) -> str:
    m = re.search(r'"message":\s*"([^"]+)"', err)
    return m.group(1) if m else err[:200]


def main(csv_path: str) -> int:
    rows = list(csv.DictReader(open(csv_path, "r", encoding="utf-8")))
    for r in rows:
        if not r.get("sut_error"):
            continue
        print("=" * 90)
        print(f"CASE: {r['case_id']}")
        print(f"NLQ:  {r['natural_language_question']}")
        print(f"\nERROR: {_extract_msg(r['sut_error'])}")
        print("\nLLM SQL:")
        print(r.get("sql_used") or "(none)")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1
                  else "audits/eval_suite/runs/run-20260614T103812Z.csv"))
