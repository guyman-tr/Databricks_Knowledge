"""Trace where Options_PFOF lives in Synapse for 2026-06-08."""
from __future__ import annotations
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

print("=== 1. Persisted fact: BI_DB_DDR_Fact_Revenue_Generating_Actions ===")
r = synapse.run("""
SELECT Metric, COUNT_BIG(*) AS rows_, SUM(Amount) AS amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID = 20260608 AND IncludedInTotalRevenue = 1
GROUP BY Metric ORDER BY amt DESC
""")
for row in r.rows: print(f"  {row[0]:30s} rows={row[1]:>10,d}  amt={float(row[2] or 0):>16,.2f}")
print()

print("=== 2. The view BI_DB_V_DDR_Revenue_Breakdown (used by the TVF) ===")
r = synapse.run("""
SELECT COUNT_BIG(*) AS rows_,
       SUM(Options_PFOF) AS options_pfof,
       SUM(TotalRevenue) AS total_revenue
FROM BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown
WHERE Date = '2026-06-08'
""")
print("  ", r.rows[0])
print()

print("=== 3. The TVF directly ===")
r = synapse.run("""
SELECT SUM(TotalRevenue) AS total_revenue
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('20260608', 0)
""")
print("  ", r.rows[0])
print()

print("=== 4. Does the view definition mention Options_PFOF or its source? ===")
r = synapse.run("""
SELECT m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'BI_DB_V_DDR_Revenue_Breakdown'
""")
defn = r.rows[0][0]
print(f"  view chars: {len(defn)}")
# Find Options_PFOF context
import re
for m in re.finditer(r'Options_PFOF|options[ _]pfof', defn, re.IGNORECASE):
    s = max(0, m.start() - 80); e = min(len(defn), m.end() + 80)
    print(f"  ...{defn[s:e].strip()}...")
print()

print("=== 5. Check if the view UNIONs in something from external tables ===")
# Look at FROM/JOIN clauses in the view
froms = re.findall(r'(?:FROM|JOIN)\s+([A-Za-z0-9_\[\]\.]+)', defn, re.IGNORECASE)
print("  unique sources:")
for s in sorted(set(froms)): print(f"    {s}")
