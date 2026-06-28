#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parents[3]))
from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()

sql = (
    "SELECT routine_definition FROM system.information_schema.routines "
    "WHERE routine_catalog='dwh_daily_process' "
    "AND routine_schema='migration_tables' "
    "AND routine_name='sp_dim_position_dl_to_synapse'"
)
_, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
body = str(rows[0][0])

for label, search in [
    ("InitForex (Real)", "Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID"),
    ("EndForex (History)", "Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.EndForexPriceRateID"),
]:
    idx = body.find(search)
    print(f"\n=== {label} @ {idx} ===")
    print(repr(body[max(0, idx-50):idx+300]))
