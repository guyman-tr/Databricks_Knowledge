"""Check row counts and etr_ymd distribution in parallel tables that failed."""
import sys, os
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"
schema = "dwh_daily_process.migration_parallel"

tables = [
    ("fact_customeraction", True),
    ("Fact_History_Cost", True),
    ("Fact_Guru_Copiers", True),
    ("fact_billingredeem", True),
    ("fact_regulationtransfer", True),
    ("Dim_PositionChangeLog", True),
    ("fact_customerunrealized_pnl", True),
]

for tbl, has_ymd in tables:
    fqn = f"{schema}.{tbl}"
    print(f"\n--- {tbl} ---")
    try:
        _, rows = execute_sql(w, sql_text=f"SELECT COUNT(*) FROM {fqn}", warehouse_id=wid)
        print(f"  total rows: {int(rows[0][0]):,}")
    except Exception as e:
        print(f"  COUNT error: {e}")
        continue
    if has_ymd:
        try:
            _, rows = execute_sql(w,
                sql_text=f"SELECT etr_ymd, COUNT(*) AS n FROM {fqn} GROUP BY etr_ymd ORDER BY etr_ymd DESC LIMIT 5",
                warehouse_id=wid)
            for r in rows:
                print(f"  etr_ymd={r[0]}  n={int(r[1]):,}")
        except Exception as e:
            print(f"  YMD breakdown error: {e}")
