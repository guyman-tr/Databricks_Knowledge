"""Check etoro_History_GuruCopiers snapshot columns and TIMESTAMP filter."""
import sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

# Column schema
_, rows = execute_sql(w,
    sql_text="DESCRIBE TABLE dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers",
    warehouse_id=wid)
print("=== etoro_History_GuruCopiers columns ===")
for r in rows:
    print(f"  {r[0]:<35} {r[1]}")

# Count & date range
_, rows2 = execute_sql(w,
    sql_text=(
        "SELECT COUNT(*) as n, "
        "COUNT(DISTINCT TIMESTAMP) as distinct_ts_vals, "
        "MIN(TIMESTAMP) as min_ts, MAX(TIMESTAMP) as max_ts "
        "FROM dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers"
    ),
    warehouse_id=wid)
if rows2:
    print(f"\ntotal_rows={rows2[0][0]}  distinct_timestamps={rows2[0][1]}  min={rows2[0][2]}  max={rows2[0][3]}")
