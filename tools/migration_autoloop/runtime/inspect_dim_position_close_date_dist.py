#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


SQL = """
SELECT 'migration' AS side, CloseDateID, COUNT(*) AS rows_cnt
FROM dwh_daily_process.migration_tables.dim_position
GROUP BY CloseDateID
ORDER BY rows_cnt DESC
LIMIT 10
"""

SQL_GOLD = """
SELECT 'gold' AS side, CloseDateID, COUNT(*) AS rows_cnt
FROM main.dwh.dim_position
GROUP BY CloseDateID
ORDER BY rows_cnt DESC
LIMIT 10
"""


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols1, rows1 = execute_sql(w, sql_text=SQL, warehouse_id=wid)
    cols2, rows2 = execute_sql(w, sql_text=SQL_GOLD, warehouse_id=wid)
    print(
        json.dumps(
            {
                "migration": {"columns": cols1, "rows": rows1},
                "gold": {"columns": cols2, "rows": rows2},
            },
            indent=2,
            default=str,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
