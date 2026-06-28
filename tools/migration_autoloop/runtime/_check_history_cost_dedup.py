"""Check CostID duplicates in HistoryCosts_History_Costs snapshot."""
import sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

# Check unique CostIDs
_, rows = execute_sql(w,
    sql_text=(
        "SELECT COUNT(DISTINCT CostID) as unique_cost_ids, "
        "COUNT(*) as total_rows, "
        "COUNT(*) - COUNT(DISTINCT CostID) as duplicates "
        "FROM dwh_daily_process.daily_snapshot.HistoryCosts_History_Costs"
    ),
    warehouse_id=wid)
if rows:
    print(f"unique_cost_ids={rows[0][0]}  total_rows={rows[0][1]}  duplicates={rows[0][2]}")

# Also check InserDate distribution to understand versioning
_, rows2 = execute_sql(w,
    sql_text=(
        "SELECT DATE_TRUNC('hour', InserDate) as hour_bucket, COUNT(*) as n "
        "FROM dwh_daily_process.daily_snapshot.HistoryCosts_History_Costs "
        "GROUP BY 1 ORDER BY 1"
    ),
    warehouse_id=wid)
print("\nInserDate distribution (hourly):")
for r in rows2:
    print(f"  {r[0]}  n={r[1]}")
