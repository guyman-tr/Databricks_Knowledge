"""Diagnose fact_guru_copiers 0 rows issue."""
import sys
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

# 1. Check what procs exist in migration_parallel for guru_copiers
_, rows = execute_sql(w,
    sql_text=(
        "SELECT routine_name FROM dwh_daily_process.information_schema.routines "
        "WHERE specific_schema='migration_parallel' AND routine_name LIKE '%guru%'"
    ),
    warehouse_id=wid)
print("=== Guru-related procs in migration_parallel ===")
for r in rows:
    print(f"  {r[0]}")

# 2. Check Ext_FGC_Guru_Copiers row count
_, rows2 = execute_sql(w,
    sql_text="SELECT COUNT(*) FROM dwh_daily_process.migration_parallel.Ext_FGC_Guru_Copiers",
    warehouse_id=wid)
print(f"\nExt_FGC_Guru_Copiers rows: {rows2[0][0] if rows2 else 'TABLE_NOT_FOUND'}")

# 3. Test the timestamp filter directly
_, rows3 = execute_sql(w,
    sql_text=(
        "SELECT COUNT(*) FROM dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers "
        "WHERE TIMESTAMP = CAST('2026-06-25' AS TIMESTAMP)"
    ),
    warehouse_id=wid)
print(f"\netoro_History_GuruCopiers WHERE TIMESTAMP=2026-06-25: {rows3[0][0] if rows3 else 'ERROR'}")

# 4. Fetch SP_Fact_Guru_Copiers helper body
_, rows4 = execute_sql(w,
    sql_text=(
        "SELECT routine_definition FROM dwh_daily_process.information_schema.routines "
        "WHERE specific_schema='migration_parallel' AND LOWER(routine_name)=LOWER('SP_Fact_Guru_Copiers')"
    ),
    warehouse_id=wid)
print(f"\n=== SP_Fact_Guru_Copiers body ===")
if rows4 and rows4[0][0]:
    print(rows4[0][0][:3000])
else:
    print("  NOT FOUND")
