#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--like", required=True, help="substring for proc_name, case-insensitive")
    args = ap.parse_args()
    like = args.like.lower().replace("'", "''")
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = f"""
SELECT
  event_ts, flow_key, proc_name, target_date, run_status, parity_pass,
  return_code, mapped_table_count, pass_count, fail_count, notes
FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE lower(proc_name) LIKE '%{like}%'
ORDER BY event_ts DESC
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
