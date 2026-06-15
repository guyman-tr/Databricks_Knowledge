"""Compare Synapse Function_Revenue_OptionsPlatform vs UC v_revenue_optionsplatform."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

print("=== Synapse: Function_Revenue_OptionsPlatform definition ===")
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_OptionsPlatform'
""")
if r.rows:
    print(r.rows[0][0])
else:
    print("  not found")

print()
print("=== Synapse: row counts of Options data per day, last 60d (using TVF directly) ===")
r = synapse.run("""
SELECT TOP 60 DateID, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.Function_Revenue_OptionsPlatform(20260401, 20260610, 0)
GROUP BY DateID
ORDER BY DateID DESC
""")
for row in r.rows[:25]:
    print(f"  Synapse TVF DateID={row[0]} rows={row[1]} sum_amt={row[2]}")
