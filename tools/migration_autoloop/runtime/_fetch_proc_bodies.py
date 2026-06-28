"""Fetch proc bodies for failing targets from information_schema."""
import sys, os
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

procs = [
    "sp_fact_guru_copiers_dl_to_synapse",
    "sp_fact_billingredeem_dl_to_synapse",
    "sp_fact_regulationtransfer_dl_to_synapse",
    "sp_dim_positionchangelog_dl_to_synapse",
    "sp_fact_customerunrealized_pnl_dl_to_synapse",
]

for proc in procs:
    print(f"\n{'='*70}")
    print(f"PROC: {proc}")
    print('='*70)
    try:
        _, rows = execute_sql(w,
            sql_text=(
                "SELECT routine_definition FROM dwh_daily_process.information_schema.routines "
                f"WHERE specific_schema='migration_tables' AND LOWER(routine_name)=LOWER('{proc}')"
            ),
            warehouse_id=wid)
        if rows and rows[0][0]:
            print(rows[0][0][:3000])
        else:
            print("  NOT FOUND")
    except Exception as e:
        print(f"  ERROR: {e}")
