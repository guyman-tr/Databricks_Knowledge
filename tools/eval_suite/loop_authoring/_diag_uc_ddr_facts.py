"""List UC ddr_fact_* tables in main.bi_db (revenue, mimo, aum, pnl)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from dbx import make_client, run_sql

w = make_client()
r = run_sql(w, "SHOW TABLES IN main.bi_db")
print("DDR fact tables:")
for row in r.rows:
    name = str(row[1])
    if 'ddr' in name.lower() and ('fact' in name.lower() or 'customer_daily' in name.lower()):
        print(f"  {name}")
