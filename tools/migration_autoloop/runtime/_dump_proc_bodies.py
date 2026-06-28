#!/usr/bin/env python3
"""Temp: dump proc bodies + their migration_tables references for design verification."""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[3]))
from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()

procs = [
    "sp_dim_mirror_dl_to_synapse_autopoc",
    "sp_fact_billingdeposit_dl_to_synapse_autopoc",
]
out_dir = Path("tools/migration_autoloop/runtime/_proc_dumps")
out_dir.mkdir(parents=True, exist_ok=True)

for p in procs:
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' AND routine_schema='migration_tables' "
            f"AND routine_name='{p}'"
        ),
        warehouse_id=wid,
    )
    body = str(rows[0][0]) if rows else ""
    (out_dir / f"{p}.sql").write_text(body, encoding="utf-8")
    refs = sorted(set(re.findall(r"dwh_daily_process\.(migration_tables|daily_snapshot)\.([A-Za-z0-9_]+)", body, re.I)))
    other = sorted(set(re.findall(r"main\.[a-z_]+\.[A-Za-z0-9_]+", body, re.I)))
    print(f"\n===== {p} (len={len(body)}) =====")
    print("migration_tables/daily_snapshot refs:")
    for schema, tbl in refs:
        print(f"  {schema}.{tbl}")
    if other:
        print("main.* refs:")
        for o in other:
            print(f"  {o}")
