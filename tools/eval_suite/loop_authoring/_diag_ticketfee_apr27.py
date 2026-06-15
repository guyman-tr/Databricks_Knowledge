"""Verify TicketFee/TicketFeeByPercent label-mix math on the 3 affected days."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

dates = [20260427, 20260428, 20260526]

print("=== UC: TicketFee + TicketFeeByPercent presence per affected day ===")
for d in dates:
    r = run_sql(w, f"""
SELECT Metric, COUNT(*) AS rows_, SUM(Amount) AS sum_amt, MIN(UpdateDate) AS min_upd, MAX(UpdateDate) AS max_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE DateID = {d} AND Metric IN ('TicketFee', 'TicketFeeByPercent')
GROUP BY Metric
ORDER BY Metric
""")
    print(f"\n  --- DateID = {d} ---")
    for row in r.rows:
        print(f"    {row[0]:<22} rows={row[1]:>6}  sum={float(row[2]):>14.4f}  min_upd={row[3]}  max_upd={row[4]}")

print()
print("=== UC: v_ddr_revenues source view emits both labels for those days ===")
for d in dates:
    r = run_sql(w, f"""
SELECT Metric, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM main.etoro_kpi_prep.v_ddr_revenues
WHERE DateID = {d} AND Metric IN ('TicketFee', 'TicketFeeByPercent')
GROUP BY Metric
ORDER BY Metric
""")
    print(f"\n  --- DateID = {d} ---")
    for row in r.rows:
        print(f"    {row[0]:<22} rows={row[1]:>6}  sum={float(row[2]):>14.4f}")
