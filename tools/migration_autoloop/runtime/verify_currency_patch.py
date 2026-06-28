#!/usr/bin/env python3
"""Dry-run: apply _patch_main and verify the 3 CurrencyPrice replacements fired."""
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parents[3]))
from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.patch_dim_position_full_autopoc import _patch_main

w = make_workspace_client()
wid = warehouse_id_from_env()
_, rows = execute_sql(
    w,
    sql_text=(
        "SELECT routine_definition FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        "AND routine_name='sp_dim_position_dl_to_synapse'"
    ),
    warehouse_id=wid,
)
body = str(rows[0][0])
patched = _patch_main(body)

checks = [
    ("MERGE 1 old ON gone",     "COALESCE(p.InitForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.InitForexPriceRateID" not in patched),
    ("MERGE 3 old ON gone",     "COALESCE(p.EndForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.EndForexPriceRateID" not in patched),
    ("MERGE 1 new ON present",  "ON p.PositionID = p_TGT.PositionID" in patched),
    ("MERGE 2 WHERE clause",    "WHERE p.OpenDateID = CAST(date_format(CAST(V_Yesterday AS DATE), 'yyyyMMdd') AS INT)" in patched),
]
for label, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'}  {label}")
