"""Parse the MCP markdown-table output of sys.tables.modify_date into a CSV.

Input : agent-tools/<uuid>.txt produced by execute_sql_read_only
Output: audits/blacklist/_a3_work/modify_dates.csv  (schema, table, create_date, modify_date)
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]


def main(src_path: str) -> int:
    src = Path(src_path)
    rows: list[tuple[str, str, str, str]] = []
    with src.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("| "):
                continue
            parts = [p.strip() for p in line.strip("|").split("|")]
            if len(parts) < 4:
                continue
            if parts[0] in ("schema_name", "---"):
                continue
            schema, table, create_date, modify_date = parts[0], parts[1], parts[2], parts[3]
            rows.append((schema, table, create_date, modify_date))

    out = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "modify_dates.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["schema", "table_name", "create_date", "modify_date"])
        w.writerows(rows)

    print(f"[modify] wrote {len(rows)} rows -> {out}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: parse_modify_dates.py <src.txt>")
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1]))
