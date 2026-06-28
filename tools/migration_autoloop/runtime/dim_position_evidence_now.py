#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    qa_sql = """
WITH bounds AS (
  SELECT LEAST(
    (SELECT MAX(OpenDateID) FROM dwh_daily_process.migration_tables.dim_position),
    (SELECT MAX(OpenDateID) FROM main.dwh.dim_position)
  ) AS common_open_date
),
agg AS (
  SELECT
    b.common_open_date,
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_rows,
    (SELECT COUNT(*) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_rows,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.Amount, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.Amount, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.CommissionOnClose, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_commission_on_close,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.CommissionOnClose, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_commission_on_close
  FROM bounds b
)
SELECT * FROM agg
"""
    trace_sql = """
SELECT
  SUM(CASE WHEN lower(statement_text) LIKE '%sp_dim_position_dl_to_synapse_autopoc%' THEN 1 ELSE 0 END) AS main_calls,
  SUM(CASE WHEN lower(statement_text) LIKE '%sp_dim_position_hedgetype_history_autopoc%' THEN 1 ELSE 0 END) AS hedgetype_history_calls,
  SUM(CASE WHEN lower(statement_text) LIKE '%sp_dim_position_hedgetype_real_autopoc%' THEN 1 ELSE 0 END) AS hedgetype_real_calls,
  SUM(CASE WHEN lower(statement_text) LIKE '%sp_dim_position_ispartialcloseparent_autopoc%' THEN 1 ELSE 0 END) AS ispartialcloseparent_calls,
  SUM(CASE WHEN lower(statement_text) LIKE '%sp_dim_position_reopen_autopoc%' THEN 1 ELSE 0 END) AS reopen_calls
FROM system.query.history
WHERE start_time >= DATEADD(HOUR, -2, current_timestamp())
"""
    q_cols, q_rows = execute_sql(w, sql_text=qa_sql, warehouse_id=wid)
    t_cols, t_rows = execute_sql(w, sql_text=trace_sql, warehouse_id=wid)
    print(
        json.dumps(
            {
                "qa_probe": {"columns": q_cols, "rows": q_rows},
                "sp_trace": {"columns": t_cols, "rows": t_rows},
            },
            indent=2,
            default=str,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
