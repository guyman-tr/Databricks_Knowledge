"""Drill ONE specific staking row end-to-end.

Pick a confusing day from the 3-way: PaidDateID=20231005 where Synapse+UC say
$582,883.55 across 488,130 CIDs but v_revenue_stakingfee says $0.

Trace one specific (CID, StakingMonthID) tuple from that 488k cohort:
  1. What does Dealing_Staking_Results show? — UpdateDate, StakingMonthID, amounts.
  2. What does Function_Revenue_StakingFee return for the source-month window?
     What's its DateID, what's its Date?
  3. Which PaidDateID does the Synapse SP STEP 3 compute via DATEADD(MONTH,1,frcf.Date)?
  4. Which PaidDateID does my Spark emulation compute via ADD_MONTHS(to_date(s.DateID,'yyyyMMdd'),1)?
  5. Where does Synapse fact actually have the row?
  6. Where does UC fact actually have the row?
  7. Where does v_revenue_stakingfee see the source row (and does it match Function_Revenue_StakingFee)?

If 3 == 4 == 5 == 6, my script's date arithmetic was correct.
If 3 == 5 == 6 but 4 differs, my Spark emulation has a date-format bug.
If 5 == 6 but != truth-view, then we have real drift.
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

# Step A: pick a sample CID from the 488k Synapse-fact cohort on 20231005
print("=" * 78)
print("(A) Sample 5 CIDs from Synapse fact: PaidDateID=20231005, StakingLagOneMonth")
print("=" * 78)
r = synapse.run("""
SELECT TOP 5 RealCID, ActionType, Amount, IsSettled, UpdateDate
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth' AND DateID = 20231005
ORDER BY Amount DESC
""")
sample_cids = []
for row in r.rows:
    print(f"  {row}")
    sample_cids.append(int(row[0]))

# Pick the highest-amount CID for forensic drill
target_cid = sample_cids[0]
print(f"\n  drill target CID = {target_cid}")

# Step B: Dealing_Staking_Results — what's the source for this CID?
print()
print("=" * 78)
print(f"(B) Dealing_Staking_Results for CID={target_cid}")
print("=" * 78)
r = synapse.run(f"""
SELECT StakingMonthID, UpdateDate, AirdropOccurred, IsEligible,
       Etoro_Amount_USD, USD_Compensation, ActualCompensationType
FROM Dealing_dbo.Dealing_Staking_Results
WHERE CID = {target_cid}
ORDER BY UpdateDate
""")
for row in r.rows:
    print(f"  {row}")

# Step C: Function_Revenue_StakingFee for an early window covering UpdateDate
# We know UpdateDate landed in early Oct 2023 since fact PaidDateID=20231005.
# TVF's @sdate/@edate filter on `dateadd(MONTH,-1,dss.UpdateDate)` so for Oct
# distributions we filter on Sep dates: 20230901..20230930.
print()
print("=" * 78)
print(f"(C) Function_Revenue_StakingFee for source month Sept 2023 (20230901..20230930), CID={target_cid}")
print("=" * 78)
r = synapse.run(f"""
SELECT [Date], DateID, StakingMonthID, CID, TotalUSDDistributed
FROM BI_DB_dbo.Function_Revenue_StakingFee(20230901, 20230930)
WHERE CID = {target_cid}
""")
for row in r.rows:
    print(f"  Date={row[0]} DateID={row[1]} StakingMonthID={row[2]} TotalUSDDistributed={row[4]}")

# Step D: Where does Synapse SP STEP 3 PUT this row?
# Per L1365: DateID = CAST(FORMAT(CAST(DATEADD(MONTH,1,frcf.Date) AS DATE),'yyyyMMdd') as INT)
# So it shifts the TVF's `Date` (timestamp) forward 1 month and formats.
print()
print("=" * 78)
print(f"(D) Synapse SP STEP 3 shift logic: DATEADD(MONTH, 1, frcf.Date), CAST to yyyyMMdd")
print("=" * 78)
r = synapse.run(f"""
SELECT [Date],
       CAST(FORMAT(CAST(DATEADD(MONTH,1,[Date]) AS DATE),'yyyyMMdd') AS INT) AS SP_PaidDateID
FROM BI_DB_dbo.Function_Revenue_StakingFee(20230901, 20230930)
WHERE CID = {target_cid}
""")
sp_paid_date = None
for row in r.rows:
    print(f"  Date={row[0]}  ->  SP_PaidDateID={row[1]}")
    sp_paid_date = int(row[1])

# Step E: My Spark emulation shift
print()
print("=" * 78)
print(f"(E) My Spark emulation: ADD_MONTHS(to_date(s.DateID,'yyyyMMdd'), 1)")
print("=" * 78)
r = run_sql(w, f"""
SELECT s.DateID,
       CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT) AS Spark_PaidDateID
FROM main.etoro_kpi_prep.v_revenue_stakingfee s
WHERE s.CID = {target_cid} AND s.DateID BETWEEN 20230901 AND 20230930
""")
spark_paid_date = None
for row in r.rows:
    print(f"  s.DateID={row[0]}  ->  Spark_PaidDateID={row[1]}")
    spark_paid_date = int(row[1])

# Step F: Where does Synapse fact actually carry this CID's row?
print()
print("=" * 78)
print(f"(F) Synapse fact: where do StakingLagOneMonth rows for CID={target_cid} actually live?")
print("=" * 78)
r = synapse.run(f"""
SELECT DateID, Amount, UpdateDate
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth' AND RealCID = {target_cid}
ORDER BY DateID
""")
syn_dates = []
for row in r.rows:
    print(f"  DateID={row[0]} Amount={row[1]} UpdateDate={row[2]}")
    syn_dates.append(int(row[0]))

# Step G: Where does UC fact carry this row?
print()
print("=" * 78)
print(f"(G) UC fact: where do StakingLagOneMonth rows for CID={target_cid} actually live?")
print("=" * 78)
r = run_sql(w, f"""
SELECT DateID, Amount, UpdateDate
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth' AND RealCID = {target_cid}
ORDER BY DateID
""")
uc_dates = []
for row in r.rows:
    print(f"  DateID={row[0]} Amount={row[1]} UpdateDate={row[2]}")
    uc_dates.append(int(row[0]))

print()
print("=" * 78)
print("VERDICT")
print("=" * 78)
print(f"  Synapse SP STEP 3 PaidDateID for this CID's source-Sep row:  {sp_paid_date}")
print(f"  My Spark emulation PaidDateID for the same source row:        {spark_paid_date}")
print(f"  Where Synapse fact actually has it:                           {syn_dates}")
print(f"  Where UC fact actually has it:                                {uc_dates}")

if sp_paid_date == spark_paid_date and sp_paid_date in syn_dates:
    print("  -> emulation matches the Synapse SP semantics. Real drift.")
elif sp_paid_date in syn_dates and spark_paid_date not in syn_dates:
    print("  -> MY EMULATION IS WRONG. The Synapse SP shifts a TIMESTAMP, my emulation shifts an INT-DateID, they differ at end-of-month.")
elif spark_paid_date in syn_dates:
    print("  -> emulation correct, Synapse SP code-comment misread.")
else:
    print("  -> neither matches; deeper investigation needed.")
