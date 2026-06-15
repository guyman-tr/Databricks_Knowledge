"""Find a CID in March that received both 03-07 and 03-09 distributions, see how UC fact handled it."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

print("=== UC source view: CIDs by date ===")
r = run_sql(w, """
WITH a AS (
  SELECT DISTINCT CID FROM main.etoro_kpi_prep.v_revenue_stakingfee WHERE DateID = 20260307
), b AS (
  SELECT DISTINCT CID FROM main.etoro_kpi_prep.v_revenue_stakingfee WHERE DateID = 20260309
)
SELECT
  (SELECT COUNT(*) FROM a) AS only_on_0307,
  (SELECT COUNT(*) FROM b) AS only_on_0309,
  (SELECT COUNT(*) FROM (SELECT CID FROM a INTERSECT SELECT CID FROM b)) AS both_dates,
  (SELECT COUNT(*) FROM (SELECT CID FROM a EXCEPT SELECT CID FROM b)) AS in_07_only,
  (SELECT COUNT(*) FROM (SELECT CID FROM b EXCEPT SELECT CID FROM a)) AS in_09_only
""")
for row in r.rows:
    print(f"  on 03-07: {row[0]}, on 03-09: {row[1]}, both: {row[2]}, only-07: {row[3]}, only-09: {row[4]}")

print()
print("=== Pick a CID that got BOTH and look at UC fact ===")
r = run_sql(w, """
SELECT a.CID FROM
  (SELECT DISTINCT CID FROM main.etoro_kpi_prep.v_revenue_stakingfee WHERE DateID = 20260307) a
  JOIN
  (SELECT DISTINCT CID FROM main.etoro_kpi_prep.v_revenue_stakingfee WHERE DateID = 20260309) b
  ON a.CID = b.CID
LIMIT 1
""")
sample_cid = int(r.rows[0][0]) if r.rows else None
print(f"  sample CID with rows on BOTH dates: {sample_cid}")

if sample_cid:
    print()
    print(f"=== UC source view rows for CID = {sample_cid}, March 2026 ===")
    r = run_sql(w, f"""
SELECT DateID, InstrumentID, Instrument, IsEligible, Etoro_Amount_USD, USD_Compensation, TotalUSDDistributed
FROM main.etoro_kpi_prep.v_revenue_stakingfee
WHERE CID = {sample_cid} AND DateID BETWEEN 20260301 AND 20260331
ORDER BY DateID, InstrumentID
""")
    total = 0.0
    for row in r.rows:
        v = float(row[6]) if row[6] is not None else 0.0
        total += v
        print(f"  DateID={row[0]} inst={row[1]} {row[2]} elig={row[3]} etoro_usd={row[4]} client_usd={row[5]} total={v}")
    print(f"  CID's total across all March rows: {total}")

    print()
    print(f"=== UC FACT rows for CID = {sample_cid}, April 2026 ===")
    r = run_sql(w, f"""
SELECT DateID, Metric, RealCID, Amount, UpdateDate
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE RealCID = {sample_cid} AND DateID BETWEEN 20260401 AND 20260430
  AND Metric = 'StakingLagOneMonth'
ORDER BY DateID
""")
    for row in r.rows:
        print(f"  DateID={row[0]} CID={row[2]} amount={float(row[3]):.4f} max_upd={row[4]}")

    print()
    print(f"=== Synapse FACT rows for CID = {sample_cid}, April 2026 ===")
    r = synapse.run(f"""
SELECT DateID, Metric, RealCID, Amount, UpdateDate
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE RealCID = {sample_cid} AND DateID BETWEEN 20260401 AND 20260430
  AND Metric = 'StakingLagOneMonth'
ORDER BY DateID
""")
    for row in r.rows:
        print(f"  DateID={row[0]} CID={row[2]} amount={float(row[3] or 0.0):.4f} max_upd={row[4]}")
