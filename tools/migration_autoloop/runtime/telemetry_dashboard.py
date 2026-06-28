#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _query(sql: str):
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    return {"columns": cols, "rows": rows}


def main() -> int:
    latest = _query(
        """
WITH ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY flow_key ORDER BY event_ts DESC) AS rn
  FROM dwh_daily_process.qa.autoloop_flow_telemetry
)
SELECT
  flow_key, proc_name, target_date, run_status, parity_pass,
  return_code, mapped_table_count, pass_count, fail_count, cumulative_mid_usd, event_ts
FROM ranked
WHERE rn = 1
ORDER BY flow_key
"""
    )
    status_counts = _query(
        """
SELECT run_status, COUNT(*) AS flow_count
FROM (
  SELECT flow_key, run_status,
         ROW_NUMBER() OVER (PARTITION BY flow_key ORDER BY event_ts DESC) AS rn
  FROM dwh_daily_process.qa.autoloop_flow_telemetry
) x
WHERE rn = 1
GROUP BY run_status
ORDER BY flow_count DESC, run_status
"""
    )
    recent = _query(
        """
SELECT event_ts, flow_key, proc_name, run_status, parity_pass, notes
FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE event_ts >= DATEADD(HOUR, -1, current_timestamp())
ORDER BY event_ts DESC
LIMIT 30
"""
    )
    print(json.dumps({"latest_per_flow": latest, "status_counts": status_counts, "recent_1h": recent}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
