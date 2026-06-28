#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[4]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = """
    WITH mig_dates AS (
      SELECT MAX(CAST(LEFT(CAST(DateRangeID AS STRING), 8) AS INT)) AS d
      FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
    ),
    gold_dates AS (
      SELECT MAX(CAST(LEFT(CAST(DateRangeID AS STRING), 8) AS INT)) AS d
      FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
    ),
    common_date AS (
      SELECT LEAST(mig_dates.d, gold_dates.d) AS d FROM mig_dates CROSS JOIN gold_dates
    ),
    mig AS (
      SELECT
        COUNT(*) AS rows_cnt,
        SUM(CAST(COALESCE(CAST(IsDepositor AS INT), 0) AS DECIMAL(38,10))) AS sum_isdepositor
      FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
      WHERE LEFT(CAST(DateRangeID AS STRING), 8) = CAST((SELECT d FROM common_date) AS STRING)
    ),
    gold AS (
      SELECT
        COUNT(*) AS rows_cnt,
        SUM(CAST(COALESCE(CAST(IsDepositor AS INT), 0) AS DECIMAL(38,10))) AS sum_isdepositor
      FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
      WHERE LEFT(CAST(DateRangeID AS STRING), 8) = CAST((SELECT d FROM common_date) AS STRING)
    )
    SELECT
      (SELECT d FROM common_date) AS common_date_id,
      mig.rows_cnt AS migration_rows,
      gold.rows_cnt AS gold_rows,
      mig.rows_cnt - gold.rows_cnt AS delta_rows,
      mig.sum_isdepositor AS migration_sum_isdepositor,
      gold.sum_isdepositor AS gold_sum_isdepositor,
      mig.sum_isdepositor - gold.sum_isdepositor AS delta_sum_isdepositor
    FROM mig CROSS JOIN gold
    """
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    result = {c: rows[0][i] for i, c in enumerate(cols)} if rows else {}
    print(json.dumps(result, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
