"""All-time 3-way StakingLagOneMonth comparison:
   - V = main.etoro_kpi_prep.v_revenue_stakingfee (the truth — post-backdating)
   - U = main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions (UC fact, what's there now)
   - S = BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions (Synapse fact)

We ALREADY know (from this morning) that 3 day-rows in UC are wrong vs Synapse.
We need to know: are there OTHER day-rows where U == S but V differs from both?
That would mean Synapse fact is also stale and the all-metrics sweep gave a
false-clean. The SP-style rewrite from V is the truth in those cases.

Outputs:
   audits/eval_suite/staking_alltime_3way.csv  — every DateID where ANY two of (V/U/S) disagree
   audits/eval_suite/staking_alltime_3way.txt  — top deltas + summary
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import csv
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

print("=" * 78)
print("All-time StakingLagOneMonth 3-way reconciliation")
print("=" * 78)
print()

# Probe: how far back does v_revenue_stakingfee go?
print("[1/5] v_revenue_stakingfee horizon:")
r = run_sql(w, """
SELECT MIN(DateID) AS min_d, MAX(DateID) AS max_d, COUNT(DISTINCT DateID) AS days
FROM main.etoro_kpi_prep.v_revenue_stakingfee
""")
v_min, v_max, v_days = (int(r.rows[0][0]), int(r.rows[0][1]), int(r.rows[0][2])) if r.rows else (None, None, 0)
print(f"  v_revenue_stakingfee: {v_days} distinct source DateIDs, range [{v_min} - {v_max}]")

# v_revenue_stakingfee is keyed on the SOURCE date (when staking happened).
# StakingLagOneMonth in the fact lands at +1 month from source.
# So the fact horizon is roughly v_min + 1 month  -> v_max + 1 month.
print()
print("[2/5] UC fact StakingLagOneMonth horizon:")
r = run_sql(w, """
SELECT MIN(DateID) AS min_d, MAX(DateID) AS max_d, COUNT(DISTINCT DateID) AS days, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth'
""")
u_min, u_max, u_days, u_rows, u_sum = (int(r.rows[0][0]), int(r.rows[0][1]), int(r.rows[0][2]), int(r.rows[0][3]), float(r.rows[0][4] or 0.0))
print(f"  UC fact: {u_days} distinct paid DateIDs, range [{u_min} - {u_max}], {u_rows:,} rows, sum=${u_sum:,.2f}")

print()
print("[3/5] Synapse fact StakingLagOneMonth horizon:")
r = synapse.run("""
SELECT MIN(DateID) AS min_d, MAX(DateID) AS max_d, COUNT(DISTINCT DateID) AS days, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth'
""")
s_min, s_max, s_days, s_rows, s_sum = (int(r.rows[0][0]), int(r.rows[0][1]), int(r.rows[0][2]), int(r.rows[0][3]), float(r.rows[0][4] or 0.0))
print(f"  Synapse fact: {s_days} distinct paid DateIDs, range [{s_min} - {s_max}], {s_rows:,} rows, sum=${s_sum:,.2f}")

# Build the per-DateID summary from each source.
# For v_revenue_stakingfee, simulate the SP STEP 3: shift +1 month, group by paid DateID.
print()
print("[4/5] Building per-DateID summaries...")

print("  ... pulling V (v_revenue_stakingfee +1mo, all-time)...")
r = run_sql(w, """
SELECT
    CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT) AS PaidDateID,
    COUNT(DISTINCT s.CID) AS cid,
    SUM(s.TotalUSDDistributed) AS sum_amt
FROM main.etoro_kpi_prep.v_revenue_stakingfee s
GROUP BY CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT)
ORDER BY PaidDateID
""")
v_map = {int(row[0]): (int(row[1]), float(row[2] or 0.0)) for row in r.rows}
print(f"      V (truth): {len(v_map)} paid DateIDs, total cid-day=$ {sum(x[1] for x in v_map.values()):,.2f}")

print("  ... pulling U (UC fact, all-time)...")
r = run_sql(w, """
SELECT DateID, COUNT(DISTINCT RealCID) AS cid, SUM(Amount) AS sum_amt
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth'
GROUP BY DateID
ORDER BY DateID
""")
u_map = {int(row[0]): (int(row[1]), float(row[2] or 0.0)) for row in r.rows}
print(f"      U (UC fact): {len(u_map)} paid DateIDs")

print("  ... pulling S (Synapse fact, all-time)...")
r = synapse.run("""
SELECT DateID, COUNT(DISTINCT RealCID) AS cid, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth'
GROUP BY DateID
ORDER BY DateID
""")
s_map = {int(row[0]): (int(row[1]), float(row[2] or 0.0)) for row in r.rows}
print(f"      S (Synapse fact): {len(s_map)} paid DateIDs")

# 3-way diff
print()
print("[5/5] 3-way reconciliation...")

all_dates = sorted(set(v_map) | set(u_map) | set(s_map))
print(f"  union of all paid DateIDs: {len(all_dates)}")

rows_out = []
issue_dates = []
for d in all_dates:
    v = v_map.get(d, (0, 0.0))
    u = u_map.get(d, (0, 0.0))
    s = s_map.get(d, (0, 0.0))
    # Status
    v_u_match = (v[0] == u[0]) and (abs(v[1] - u[1]) < 0.01)
    v_s_match = (v[0] == s[0]) and (abs(v[1] - s[1]) < 0.01)
    u_s_match = (u[0] == s[0]) and (abs(u[1] - s[1]) < 0.01)
    if v_u_match and v_s_match and u_s_match:
        status = "OK"
    elif v_u_match and not u_s_match:
        status = "S_DRIFT"            # truth=V=U, S is drifted
    elif v_s_match and not u_s_match:
        status = "U_DRIFT"            # truth=V=S, U is drifted (the 3 we already knew)
    elif u_s_match and not v_u_match:
        status = "BOTH_FACTS_STALE"   # both facts agree but disagree with V — both stale
    else:
        status = "ALL_DIFF"

    rows_out.append({
        "PaidDateID": d,
        "v_cid": v[0], "v_sum": f"{v[1]:.4f}",
        "u_cid": u[0], "u_sum": f"{u[1]:.4f}",
        "s_cid": s[0], "s_sum": f"{s[1]:.4f}",
        "u_minus_v": f"{u[1] - v[1]:.4f}",
        "s_minus_v": f"{s[1] - v[1]:.4f}",
        "u_minus_s": f"{u[1] - s[1]:.4f}",
        "status": status,
    })
    if status != "OK":
        issue_dates.append((d, v, u, s, status))

# Write CSV
out_csv = "audits/eval_suite/staking_alltime_3way.csv"
os.makedirs(os.path.dirname(out_csv), exist_ok=True)
with open(out_csv, "w", newline="", encoding="utf-8") as f:
    w_csv = csv.DictWriter(f, fieldnames=list(rows_out[0].keys()))
    w_csv.writeheader()
    for r in rows_out:
        w_csv.writerow(r)
print(f"  wrote {out_csv} ({len(rows_out)} rows)")

# Counts by status
from collections import Counter
counts = Counter(r["status"] for r in rows_out)
print(f"  status breakdown: {dict(counts)}")

# Show every issue date
print()
print(f"=== {len(issue_dates)} non-OK days ===")
print(f"  {'PaidDateID':<11} {'v_cid':>8} {'v_sum':>14} {'u_cid':>8} {'u_sum':>14} {'s_cid':>8} {'s_sum':>14} status")
for d, v, u, s, status in issue_dates:
    print(f"  {d:<11} {v[0]:>8} {v[1]:>14.2f} {u[0]:>8} {u[1]:>14.2f} {s[0]:>8} {s[1]:>14.2f} {status}")

# Aggregate effect of replacing U with V
total_u = sum(x[1] for x in u_map.values())
total_v_for_u_dates = sum(v_map.get(d, (0,0.0))[1] for d in u_map)
print()
print(f"  Current UC sum (all-time):     ${total_u:>16,.2f}")
print(f"  Truth (V) sum on UC dates:     ${total_v_for_u_dates:>16,.2f}")
print(f"  Delta (UC - V on UC dates):    ${total_u - total_v_for_u_dates:>+16,.2f}")
total_v_all = sum(x[1] for x in v_map.values())
print(f"  Truth (V) sum (all paid dates):${total_v_all:>16,.2f}")
v_only = set(v_map) - set(u_map)
v_only_sum = sum(v_map[d][1] for d in v_only)
print(f"  V-only days (missing in UC): {len(v_only)} days, ${v_only_sum:,.2f}")
