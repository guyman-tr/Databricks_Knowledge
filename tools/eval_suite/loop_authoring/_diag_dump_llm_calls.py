"""Read llm_calls (and mcp_calls' sql_excerpt) from the run CSV's `raw` blob.

Currently `raw` isn't projected to the CSV — the writer flattens specific
fields. This script just dumps the row as-is so we can see what's there.
"""
from __future__ import annotations

import csv
import sys


def main(csv_path: str) -> int:
    rows = list(csv.DictReader(open(csv_path, "r", encoding="utf-8")))
    for r in rows:
        print("CASE:", r["case_id"])
        for k, v in r.items():
            if v and len(v) > 0:
                print(f"  {k}: {v[:500]}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
