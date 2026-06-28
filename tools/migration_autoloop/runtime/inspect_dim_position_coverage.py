#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


SQL = """
WITH migration AS (
  SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CAST(CloseOccurred AS TIMESTAMP) = TIMESTAMP '1900-01-01 00:00:00' THEN 1 ELSE 0 END) AS open_rows,
    SUM(CASE WHEN CAST(CloseOccurred AS TIMESTAMP) <> TIMESTAMP '1900-01-01 00:00:00' THEN 1 ELSE 0 END) AS closed_rows,
    MIN(OpenDateID) AS min_open_dateid,
    MAX(OpenDateID) AS max_open_dateid,
    MIN(CloseDateID) AS min_close_dateid,
    MAX(CloseDateID) AS max_close_dateid,
    COUNT(DISTINCT OpenDateID) AS open_days,
    COUNT(DISTINCT CloseDateID) AS close_days
  FROM dwh_daily_process.migration_tables.dim_position
),
gold AS (
  SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CAST(CloseOccurred AS TIMESTAMP) = TIMESTAMP '1900-01-01 00:00:00' THEN 1 ELSE 0 END) AS open_rows,
    SUM(CASE WHEN CAST(CloseOccurred AS TIMESTAMP) <> TIMESTAMP '1900-01-01 00:00:00' THEN 1 ELSE 0 END) AS closed_rows,
    MIN(OpenDateID) AS min_open_dateid,
    MAX(OpenDateID) AS max_open_dateid,
    MIN(CloseDateID) AS min_close_dateid,
    MAX(CloseDateID) AS max_close_dateid,
    COUNT(DISTINCT OpenDateID) AS open_days,
    COUNT(DISTINCT CloseDateID) AS close_days
  FROM main.dwh.dim_position
)
SELECT 'migration' AS side, * FROM migration
UNION ALL
SELECT 'gold' AS side, * FROM gold
"""


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=SQL, warehouse_id=wid, poll_deadline_sec=1800.0)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
