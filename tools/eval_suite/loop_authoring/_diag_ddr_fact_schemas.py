"""Print column lists for each DDR fact table in UC, so we can map
canvas-column-names to UC fact tables."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from dbx import make_client, run_sql

FACTS = [
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum",
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl",
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms",
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status",
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts",
]

w = make_client()
for f in FACTS:
    print(f"\n===== {f} =====")
    r = run_sql(w, f"DESCRIBE TABLE {f}")
    for row in r.rows:
        name = str(row[0])
        if name.startswith("#") or not name:
            break
        typ = str(row[1])
        print(f"  {name:<40} {typ}")
