"""Diagnose StakingLagOneMonth 8x: compare the TWO sources Synapse and UC SPs read from."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

# Pick March 2026 (Synapse Apr-7 = 192,834.24, UC Apr-7 = 1,605,711.62 ⇒ ratio 8.37x)
# UC SP STEP 3 GROUP BY s.CID, s.DateID — so DateID here is the ORIGINAL (March) DateID, not the +1-month DateID.
# Synapse SP feeds Function_Revenue_StakingFee(prev_month_start, prev_month_end) for @dateID = 20260407.

print("=" * 70)
print("Cohort: March 2026 staking, paid out 2026-04-07")
print("=" * 70)

print()
print("=== Synapse: Function_Revenue_StakingFee(20260301, 20260331, 0) ===")
r = synapse.run("""
SELECT
    COUNT(*) AS rows_,
    COUNT(DISTINCT CID) AS distinct_cid,
    COUNT(DISTINCT [Date]) AS distinct_dates,
    SUM(CAST(TotalUSDDistributed AS FLOAT)) AS total_usd
FROM BI_DB_dbo.Function_Revenue_StakingFee(20260301, 20260331, 0)
""")
for row in r.rows:
    print(f"  rows={row[0]} distinct_cid={row[1]} distinct_dates={row[2]} total_usd={row[3]}")

print()
print("=== Synapse: per-day breakdown of Function_Revenue_StakingFee(20260301, 20260331, 0) ===")
r = synapse.run("""
SELECT [Date], COUNT(*) AS rows_, COUNT(DISTINCT CID) AS distinct_cid,
       SUM(CAST(TotalUSDDistributed AS FLOAT)) AS total_usd
FROM BI_DB_dbo.Function_Revenue_StakingFee(20260301, 20260331, 0)
GROUP BY [Date]
ORDER BY [Date]
""")
for row in r.rows:
    print(f"  date={row[0]} rows={row[1]} cid={row[2]} usd={row[3]:.2f}")

print()
print("=== UC: v_revenue_stakingfee for same March-2026 cohort ===")
r = run_sql(w, """
SELECT
    COUNT(*) AS rows_,
    COUNT(DISTINCT CID) AS distinct_cid,
    COUNT(DISTINCT DateID) AS distinct_dates,
    SUM(TotalUSDDistributed) AS total_usd
FROM main.etoro_kpi_prep.v_revenue_stakingfee
WHERE DateID BETWEEN 20260301 AND 20260331
""")
for row in r.rows:
    print(f"  rows={row[0]} distinct_cid={row[1]} distinct_dates={row[2]} total_usd={row[3]}")

print()
print("=== UC: per-day breakdown ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT CID) AS distinct_cid,
       SUM(TotalUSDDistributed) AS total_usd
FROM main.etoro_kpi_prep.v_revenue_stakingfee
WHERE DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID
ORDER BY DateID
""")
for row in r.rows:
    print(f"  DateID={row[0]} rows={row[1]} cid={row[2]} usd={float(row[3]):.2f}")

print()
print("=== Ratio check ===")
print("Apr-7 fact: Synapse $191,834.24  /  UC $1,605,711.62  =  8.37x")
print("If the source-view sums are equally inflated, the issue is in v_revenue_stakingfee.")
print("If the source-view sums match, the issue is in the SP STEP 3 GROUP BY.")
