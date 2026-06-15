"""Investigate the $163.15 ConversionFee drift between UC v_revenue_conversionfee
and Synapse Function_Revenue_ConversionFee for 2026-06-08."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

DATE = "20260608"

print(f"=== ConversionFee drift investigation for DateID={DATE} ===")
print()
print("--- (a) Synapse Function_Revenue_ConversionFee output (raw TVF) ---")
r = synapse.run(f"""
SELECT COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid,
       SUM(CAST(ConversionFeeInDollars AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.Function_Revenue_ConversionFee({DATE}, {DATE})
""")
for row in r.rows:
    print(f"    rows={row[0]} cid={row[1]} sum={float(row[2] or 0.0):.4f}")

print()
print("--- (b) Synapse fact ConversionFee for {DATE} ---")
r = synapse.run(f"""
SELECT COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid,
       SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'ConversionFee' AND DateID = {DATE}
""")
for row in r.rows:
    print(f"    rows={row[0]} cid={row[1]} sum={float(row[2] or 0.0):.4f}")

print()
print("--- (c) UC v_revenue_conversionfee for {DATE} ---")
try:
    r = run_sql(w, f"""
SELECT COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid, SUM(Amount) AS sum_amt
FROM main.etoro_kpi_prep.v_revenue_conversionfee
WHERE DateID = {DATE}
""")
    for row in r.rows:
        print(f"    rows={row[0]} cid={row[1]} sum={float(row[2] or 0.0):.4f}")
except Exception as e:
    print(f"    FAIL: {e}")
    # Try alternative column names
    try:
        r = run_sql(w, f"""
DESCRIBE main.etoro_kpi_prep.v_revenue_conversionfee
""")
        print("    columns of v_revenue_conversionfee:")
        for row in r.rows:
            print(f"      {row}")
    except Exception as e2:
        print(f"    DESCRIBE also FAIL: {e2}")

print()
print("--- (d) UC v_ddr_revenues ConversionFee for {DATE} ---")
r = run_sql(w, f"""
SELECT COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid, SUM(Amount) AS sum_amt
FROM main.etoro_kpi_prep.v_ddr_revenues
WHERE Metric = 'ConversionFee' AND DateID = {DATE}
""")
for row in r.rows:
    print(f"    rows={row[0]} cid={row[1]} sum={float(row[2] or 0.0):.4f}")

print()
print("--- (e) UC live target ConversionFee for {DATE} (post-backfill state) ---")
r = run_sql(w, f"""
SELECT COUNT(*) AS rows_, COUNT(DISTINCT RealCID) AS cid, SUM(Amount) AS sum_amt
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'ConversionFee' AND DateID = {DATE}
""")
for row in r.rows:
    print(f"    rows={row[0]} cid={row[1]} sum={float(row[2] or 0.0):.4f}")

print()
print("--- (f) Identify which CIDs differ — top deltas (Synapse vs UC view) ---")
# Pull both per-CID, diff, sort by abs delta
r = synapse.run(f"""
SELECT RealCID, COUNT(*) AS r, SUM(CAST(ConversionFeeInDollars AS FLOAT)) AS s
FROM BI_DB_dbo.Function_Revenue_ConversionFee({DATE}, {DATE})
GROUP BY RealCID
""")
syn_per_cid = {int(row[0]): (int(row[1]), float(row[2] or 0.0)) for row in r.rows}

r = run_sql(w, f"""
SELECT RealCID, COUNT(*) AS r, SUM(Amount) AS s
FROM main.etoro_kpi_prep.v_revenue_conversionfee
WHERE DateID = {DATE}
GROUP BY RealCID
""")
uc_per_cid = {int(row[0]): (int(row[1]), float(row[2] or 0.0)) for row in r.rows}

all_cids = set(syn_per_cid) | set(uc_per_cid)
diffs = []
for cid in all_cids:
    s = syn_per_cid.get(cid, (0, 0.0))
    u = uc_per_cid.get(cid, (0, 0.0))
    if s[0] != u[0] or abs(s[1] - u[1]) > 0.005:
        diffs.append((cid, s[0], s[1], u[0], u[1], u[1] - s[1]))

print(f"    diffing CIDs: {len(diffs)} of {len(all_cids)} total")
diffs.sort(key=lambda x: -abs(x[5]))
print(f"    {'CID':>10} {'syn_r':>6} {'syn_s':>14} {'uc_r':>6} {'uc_s':>14} {'Δ':>10}")
for d in diffs[:20]:
    print(f"    {d[0]:>10} {d[1]:>6} {d[2]:>14.4f} {d[3]:>6} {d[4]:>14.4f} {d[5]:>+10.4f}")

total_delta = sum(d[5] for d in diffs)
print()
print(f"    sum of UC-syn deltas across drifting CIDs: {total_delta:+.4f}")
