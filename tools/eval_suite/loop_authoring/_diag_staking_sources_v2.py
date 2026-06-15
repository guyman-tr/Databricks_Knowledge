"""Diagnose StakingLagOneMonth 8x — corrected: TVF takes 2 args."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=" * 70)
print("Cohort: March 2026 staking, paid out 2026-04-07")
print("=" * 70)

# ---------- 1. Synapse: full TVF body ----------
print()
print("=== Synapse: Function_Revenue_StakingFee body (full) ===")
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_StakingFee'
""")
syn_body = r.rows[0][0]
for i, ln in enumerate(syn_body.splitlines()):
    print(f"L{i+1:3d}: {ln}")
syn_body_lines = len(syn_body.splitlines())

# ---------- 2. Synapse: per-day breakdown of source TVF ----------
print()
print("=== Synapse: Function_Revenue_StakingFee(20260301, 20260331) — per-day ===")
r = synapse.run("""
SELECT [Date], COUNT(*) AS rows_, COUNT(DISTINCT CID) AS distinct_cid,
       COUNT(DISTINCT InstrumentID) AS distinct_inst,
       SUM(CAST(TotalUSDDistributed AS FLOAT)) AS total_usd
FROM BI_DB_dbo.Function_Revenue_StakingFee(20260301, 20260331)
GROUP BY [Date]
ORDER BY [Date]
""")
syn_total = 0.0
for row in r.rows:
    syn_total += float(row[4]) if row[4] is not None else 0.0
    print(f"  date={row[0]} rows={row[1]} cid={row[2]} inst={row[3]} usd={float(row[4] or 0.0):.2f}")
print(f"  Synapse TVF March-2026 total: {syn_total:.2f}")

# Group-by replicating the SP STEP 3 logic
print()
print("=== Synapse: SP STEP 3 emulation: SUM grouped by CID, DateID (after +1 month) ===")
r = synapse.run("""
SELECT
    CAST(FORMAT(CAST(DATEADD(MONTH,1,frcf.[Date]) AS DATE),'yyyyMMdd') as INT) AS PaidOnDateID,
    COUNT(DISTINCT frcf.CID) AS distinct_cid,
    COUNT(*) AS rows_in,
    SUM(CAST(frcf.TotalUSDDistributed AS FLOAT)) AS total_usd
FROM BI_DB_dbo.Function_Revenue_StakingFee(20260301, 20260331) frcf
GROUP BY CAST(FORMAT(CAST(DATEADD(MONTH,1,frcf.[Date]) AS DATE),'yyyyMMdd') as INT)
ORDER BY PaidOnDateID
""")
for row in r.rows:
    print(f"  paid={row[0]} cid={row[1]} rows={row[2]} usd={float(row[3] or 0.0):.2f}")

# ---------- 3. UC: view body ----------
print()
print("=== UC: main.etoro_kpi_prep.v_revenue_stakingfee body ===")
r = run_sql(w, """
SELECT view_definition
FROM main.information_schema.views
WHERE table_schema = 'etoro_kpi_prep' AND table_name = 'v_revenue_stakingfee'
""")
if r.rows:
    uc_body = r.rows[0][0]
    for i, ln in enumerate(uc_body.splitlines()):
        print(f"L{i+1:3d}: {ln}")
else:
    print("  not found")

# ---------- 4. UC: per-day breakdown of source view ----------
print()
print("=== UC: v_revenue_stakingfee for 20260301..20260331 — per-day ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, COUNT(DISTINCT CID) AS distinct_cid,
       COUNT(DISTINCT InstrumentID) AS distinct_inst,
       SUM(TotalUSDDistributed) AS total_usd
FROM main.etoro_kpi_prep.v_revenue_stakingfee
WHERE DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID
ORDER BY DateID
""")
uc_total = 0.0
for row in r.rows:
    uc_total += float(row[4]) if row[4] is not None else 0.0
    print(f"  DateID={row[0]} rows={row[1]} cid={row[2]} inst={row[3]} usd={float(row[4] or 0.0):.2f}")
print(f"  UC view March-2026 total: {uc_total:.2f}")

print()
print("=== Comparison ===")
print(f"  Synapse TVF March-2026 sum: {syn_total:.2f}")
print(f"  UC view    March-2026 sum: {uc_total:.2f}")
if syn_total > 0:
    print(f"  ratio UC/Syn: {uc_total/syn_total:.3f}x")
print(f"  Apr-7 fact: Synapse $191,834.24  /  UC $1,605,711.62  =  8.37x")
