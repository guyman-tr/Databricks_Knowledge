"""Check HistoryCosts_History_Costs snapshot schema and date columns."""
import sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

# 1. Get column list
_, rows = execute_sql(w,
    sql_text="DESCRIBE TABLE dwh_daily_process.daily_snapshot.HistoryCosts_History_Costs",
    warehouse_id=wid)
print("=== HistoryCosts_History_Costs columns ===")
for r in rows:
    print(f"  {r[0]:<35} {r[1]}")

# 2. Count rows and check any date-like column distributions
print("\n=== Row count and date column sample ===")
_, rows2 = execute_sql(w,
    sql_text=(
        "SELECT COUNT(*) as n, "
        "MIN(Occurred) as min_occ, MAX(Occurred) as max_occ "
        "FROM dwh_daily_process.daily_snapshot.HistoryCosts_History_Costs"
    ),
    warehouse_id=wid)
if rows2:
    print(f"  total_rows={rows2[0][0]}  min_occurred={rows2[0][1]}  max_occurred={rows2[0][2]}")
