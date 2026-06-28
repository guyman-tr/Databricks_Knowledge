#!/usr/bin/env python3
"""Backfill Dim_PositionHedgeServerChangeLog_Snapshot from 2026-05-21 to today.

Migration table is stuck at max FromDate=20260520; gold mirror is at 20260605.
Running the proc sequentially for each missing day closes the gap.
"""
from datetime import date, timedelta
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()

start = date(2026, 5, 21)
end = date(2026, 6, 24)
d = start
while d <= end:
    print(f"Running {d}...", flush=True)
    execute_sql(
        w,
        sql_text=f"CALL dwh_daily_process.migration_tables.sp_dim_positionhedgeserverchangelog_dl_to_synapse('{d}')",
        warehouse_id=wid,
        poll_deadline_sec=300.0,
    )
    d += timedelta(days=1)

print("Done.")
