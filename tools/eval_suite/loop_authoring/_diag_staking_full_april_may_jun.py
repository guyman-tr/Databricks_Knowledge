"""Look at every StakingLagOneMonth row in UC fact across April/May/June 2026
   and compare to Synapse, so we know exactly which days to rewrite."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== Synapse fact: StakingLagOneMonth, Apr-Jun 2026 ===")
r = synapse.run("""
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid,
       SUM(CAST(Amount AS FLOAT)) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN 20260401 AND 20260630
GROUP BY DateID ORDER BY DateID
""")
syn = {int(row[0]): (int(row[1]), int(row[2]), float(row[3] or 0.0), str(row[4])) for row in r.rows}
for d, v in syn.items():
    print(f"  syn DateID={d} rows={v[0]} cid={v[1]} sum={v[2]:.2f} max_upd={v[3]}")

print()
print("=== UC fact: StakingLagOneMonth, Apr-Jun 2026 ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid,
       SUM(Amount) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN 20260401 AND 20260630
GROUP BY DateID ORDER BY DateID
""")
uc = {int(row[0]): (int(row[1]), int(row[2]), float(row[3] or 0.0), str(row[4])) for row in r.rows}
for d, v in uc.items():
    print(f"  uc  DateID={d} rows={v[0]} cid={v[1]} sum={v[2]:.2f} max_upd={v[3]}")

print()
print("=== Diff ===")
all_d = sorted(set(syn) | set(uc))
print(f"  {'DateID':<10} {'syn_cid':>8} {'syn_sum':>14} {'uc_cid':>8} {'uc_sum':>14} {'Δ_cid':>7} {'Δ_sum':>14} status")
for d in all_d:
    s = syn.get(d); u = uc.get(d)
    if s and u:
        dc = s[1] - u[1]; ds = s[2] - u[2]
        ok = abs(ds) < 0.01 and dc == 0
        print(f"  {d:<10} {s[1]:>8} {s[2]:>14.2f} {u[1]:>8} {u[2]:>14.2f} {dc:>7} {ds:>14.2f} {'MATCH' if ok else 'DIFF'}")
    elif s:
        print(f"  {d:<10} {s[1]:>8} {s[2]:>14.2f} {'-':>8} {'-':>14} {'-':>7} {'-':>14} SYN_ONLY")
    elif u:
        print(f"  {d:<10} {'-':>8} {'-':>14} {u[1]:>8} {u[2]:>14.2f} {'-':>7} {'-':>14} UC_ONLY")
