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
    sql = """
WITH ranked AS (
  SELECT
    flow_key,
    run_status,
    parity_pass,
    event_ts,
    ROW_NUMBER() OVER (PARTITION BY flow_key ORDER BY event_ts DESC) AS rn
  FROM dwh_daily_process.qa.autoloop_flow_telemetry
)
SELECT flow_key, run_status, parity_pass, event_ts
FROM ranked
WHERE rn = 1
ORDER BY flow_key
"""
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
