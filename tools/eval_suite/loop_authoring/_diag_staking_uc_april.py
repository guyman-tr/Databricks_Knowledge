"""Where in UC fact does StakingLagOneMonth land for April 2026?"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== UC fact: StakingLagOneMonth rows by DateID, April 2026 ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS distinct_cid,
       SUM(Amount) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN 20260401 AND 20260430
GROUP BY DateID
ORDER BY DateID
""")
for row in r.rows:
    print(f"  DateID={row[0]} rows={row[1]} cid={row[2]} sum={float(row[3]):.2f} max_upd={row[4]}")

print()
print("=== Synapse fact: StakingLagOneMonth rows by DateID, April 2026 ===")
import synapse
r = synapse.run("""
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS distinct_cid,
       SUM(CAST(Amount AS FLOAT)) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN 20260401 AND 20260430
GROUP BY DateID
ORDER BY DateID
""")
for row in r.rows:
    print(f"  DateID={row[0]} rows={row[1]} cid={row[2]} sum={float(row[3] or 0.0):.2f} max_upd={row[4]}")
