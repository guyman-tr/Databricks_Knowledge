"""Look up Function_Revenue_StakingFee signature."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

r = synapse.run("""
SELECT p.name, t.name AS type_name, p.parameter_id, p.is_output
FROM sys.parameters p
JOIN sys.objects o ON o.object_id = p.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types t ON t.user_type_id = p.user_type_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_StakingFee'
ORDER BY p.parameter_id
""")
print("Function_Revenue_StakingFee parameters:")
for row in r.rows:
    print(f"  {row[2]}: {row[0]} ({row[1]}) is_output={row[3]}")

# Also dump the function body
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_StakingFee'
""")
if r.rows:
    body = r.rows[0][0]
    # Print first 30 lines
    for i, ln in enumerate(body.splitlines()[:50]):
        print(f"L{i+1}: {ln}")
