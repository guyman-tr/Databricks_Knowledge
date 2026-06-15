"""Compare 3-way for DateID=20260608:
   A) UC TARGET right now (post-our-Options/Staking backfills)
   B) Sandbox after SP run (the new clean re-write)
   C) Synapse fact

If the new SP output is closer to Synapse than the current target, cutting over
is a STRICT improvement.
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

TEST_DATE = "20260608"
TARGET = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
SANDBOX = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions__sp_test_20260610"


def fetch_uc(table):
    r = run_sql(w, f"""
SELECT Metric, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {table}
WHERE DateID = {TEST_DATE} AND IncludedInTotalRevenue = 1
GROUP BY Metric ORDER BY Metric
""")
    return {row[0]: (int(row[1]), float(row[2] or 0.0)) for row in r.rows}


def fetch_syn():
    r = synapse.run(f"""
SELECT Metric, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID = {TEST_DATE} AND IncludedInTotalRevenue = 1
GROUP BY Metric ORDER BY Metric
""")
    return {row[0]: (int(row[1]), float(row[2] or 0.0)) for row in r.rows}


print(f"=== 3-way comparison for DateID={TEST_DATE} ===")
print(f"  A = UC target (live) — post-our-backfills")
print(f"  B = SP output (sandbox) — what the SP wrote")
print(f"  C = Synapse fact (truth)")
print()

a = fetch_uc(TARGET)
b = fetch_uc(SANDBOX)
c = fetch_syn()

# Treat TicketFee + TicketFeeByPercent as one bucket on Synapse side for parity
# (UC merges them under TicketFee).
def merge_ticket(d):
    if 'TicketFeeByPercent' in d and 'TicketFee' in d:
        tf = d['TicketFee']
        tfp = d.pop('TicketFeeByPercent')
        d['TicketFee'] = (tf[0] + tfp[0], tf[1] + tfp[1])
    return d

c = merge_ticket(c)

all_metrics = sorted(set(a) | set(b) | set(c))
print(f"  {'Metric':<28} {'A_sum':>14} {'B_sum':>14} {'C_sum':>14} {'B-C':>10} {'A-C':>10}")
b_total = 0.0; c_total = 0.0; a_total = 0.0
for m in all_metrics:
    av = a.get(m, (0, 0.0))
    bv = b.get(m, (0, 0.0))
    cv = c.get(m, (0, 0.0))
    bc = bv[1] - cv[1]
    ac = av[1] - cv[1]
    print(f"  {m:<28} {av[1]:>14.2f} {bv[1]:>14.2f} {cv[1]:>14.2f} {bc:>10.2f} {ac:>10.2f}")
    a_total += av[1]; b_total += bv[1]; c_total += cv[1]

print()
print(f"  {'TOTAL':<28} {a_total:>14.2f} {b_total:>14.2f} {c_total:>14.2f} {b_total-c_total:>10.2f} {a_total-c_total:>10.2f}")
print()
print(f"  A - C  (live UC vs Synapse) = {a_total-c_total:+.2f}")
print(f"  B - C  (SP output vs Synapse) = {b_total-c_total:+.2f}")
