"""Inspect what columns Function_Revenue_StakingFee returns vs what
v_revenue_stakingfee exposes.

Hypothesis: my SP-emulation in _diag_staking_alltime_3way.py used
ADD_MONTHS(s.DateID, 1) but the Synapse SP uses ADD_MONTHS(frcf.Date, 1) where
.Date may be a DIFFERENT date inside the TVF (e.g. DistributionDate).
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

# Get the body of Function_Revenue_StakingFee.
print("=" * 78)
print("Synapse Function_Revenue_StakingFee — the SELECT list (first 80 lines)")
print("=" * 78)
r = synapse.run("""
SELECT m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_StakingFee'
""")
body = r.rows[0][0] if r.rows else ""
for i, ln in enumerate(body.splitlines()[:120], 1):
    print(f"  L{i:>3}: {ln}")
print(f"  ...({len(body.splitlines())} lines total)")

# Get UC v_revenue_stakingfee column list.
print()
print("=" * 78)
print("UC v_revenue_stakingfee — columns")
print("=" * 78)
r = run_sql(w, "DESCRIBE main.etoro_kpi_prep.v_revenue_stakingfee")
for row in r.rows:
    print(f"  {row}")

# Also probe: do the dates inside the TVF differ from what I assumed?
# Pull one source month with both interpretations.
print()
print("=" * 78)
print("Probe: for source MONTH = 2023-10, how does the TVF look?")
print("=" * 78)
print("  (Synapse Function_Revenue_StakingFee for sdate=20231001 edate=20231031, 0):")
try:
    r = synapse.run("""
SELECT TOP 5 *
FROM BI_DB_dbo.Function_Revenue_StakingFee(20231001, 20231031)
""")
    print(f"    columns: {r.columns}")
    for row in r.rows:
        print(f"    {row}")
except Exception as e:
    print(f"    FAIL: {e}")
