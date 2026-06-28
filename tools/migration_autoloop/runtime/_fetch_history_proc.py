"""Fetch history_cost proc bodies from migration_parallel."""
import sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

for proc in ["sp_fact_history_cost_dl_to_synapse_autopoc", "sp_fact_history_cost_autopoc"]:
    print(f"\n{'='*60}")
    print(f"PROC: {proc}")
    print('='*60)
    _, rows = execute_sql(w,
        sql_text=(
            "SELECT routine_definition FROM dwh_daily_process.information_schema.routines "
            f"WHERE specific_schema='migration_parallel' AND LOWER(routine_name)=LOWER('{proc}')"
        ),
        warehouse_id=wid)
    if rows and rows[0][0]:
        print(rows[0][0][:4000])
    else:
        print("  NOT FOUND")
