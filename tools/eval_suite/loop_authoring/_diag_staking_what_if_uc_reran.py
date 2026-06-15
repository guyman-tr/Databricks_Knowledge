"""Simulate what UC SP STEP 3 would write today if it re-ran for April 2026 cohort."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== UC SP STEP 3 simulation: what would it produce TODAY if it ran ===")
print("    (replicating: SELECT (DATEADD MONTH 1) AS DateID, SUM(TotalUSDDistributed)")
print("     FROM v_revenue_stakingfee WHERE DateID BETWEEN 20260301 AND 20260331")
print("     GROUP BY CID, DateID)")
r = run_sql(w, """
SELECT
  CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT) AS PaidDateID,
  COUNT(DISTINCT s.CID) AS distinct_cid,
  COUNT(*) AS source_rows,
  SUM(s.TotalUSDDistributed) AS sum_amt
FROM main.etoro_kpi_prep.v_revenue_stakingfee s
WHERE s.DateID BETWEEN 20260301 AND 20260331
GROUP BY CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT)
ORDER BY PaidDateID
""")
for row in r.rows:
    print(f"  paid={row[0]} cid={row[1]} src_rows={row[2]} sum={float(row[3]):.2f}")

print()
print("=== Compare to what's currently IN UC fact ===")
r = run_sql(w, """
SELECT DateID, COUNT(DISTINCT RealCID) AS distinct_cid, SUM(Amount) AS sum_amt, MAX(UpdateDate) AS upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN 20260401 AND 20260430
GROUP BY DateID
ORDER BY DateID
""")
for row in r.rows:
    print(f"  fact DateID={row[0]} cid={row[1]} sum={float(row[2]):.2f} upd={row[3]}")

print()
print("=== Conclusion ===")
print("If the simulated values match Synapse fact ($191k Apr-7 / $1.4M Apr-9),")
print("then the UC SP logic is correct and just needs to be re-run to pick up")
print("the post-comp corrections that already exist in v_revenue_stakingfee.")
