"""Fetch autopoc proc bodies for the failing targets."""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

targets = [
    "sp_fact_customeraction_etl_dl_to_synapse_autopoc",
    "sp_fact_history_cost_dl_to_synapse_autopoc",
    "sp_fact_guru_copiers_dl_to_synapse_autopoc",
    "sp_fact_billingredeem_dl_to_synapse_autopoc",
    "sp_fact_regulationtransfer_dl_to_synapse_autopoc",
]

for proc in targets:
    print(f"\n{'='*70}")
    print(f"PROC: {proc}")
    print('='*70)
    try:
        cols, rows = execute_sql(w,
            sql_text=f"SHOW CREATE PROCEDURE dwh_daily_process.migration_parallel.`{proc}`",
            warehouse_id=wid)
        if rows:
            body = rows[0][0] if rows[0] else ""
            # Print up to 3000 chars
            print(body[:3000])
    except Exception as e:
        print(f"  ERROR: {e}")
