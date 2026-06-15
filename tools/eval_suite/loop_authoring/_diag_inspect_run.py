"""Tabulate per-case error kind and the LLM-emitted SQL preview from a run CSV."""
from __future__ import annotations

import csv
import sys
from pathlib import Path


def main(csv_path: str) -> int:
    rows = list(csv.DictReader(open(csv_path, "r", encoding="utf-8")))
    header = f"{'case_id':<48} {'err_kind':<10} {'sql_len':>7}  sql_first_line"
    print(header)
    print("-" * 120)
    for r in rows:
        err = r.get("sut_error") or ""
        if "timed out" in err:
            kind = "TIMEOUT"
        elif "isError" in err:
            kind = "SQL_ERR"
        elif err:
            kind = "OTHER"
        else:
            kind = "OK"
        sql = (r.get("sql_used") or "").strip()
        first_line = sql.splitlines()[0][:60] if sql else "(no sql)"
        print(f"{r['case_id']:<48} {kind:<10} {len(sql):>7}  {first_line}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1
                  else "audits/eval_suite/runs/run-20260614T103812Z.csv"))
