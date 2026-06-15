"""Inspect Function_Revenue_ConversionFee signature + first lines of body."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import synapse

print("=== Synapse Function_Revenue_ConversionFee signature ===")
r = synapse.run("""
SELECT p.parameter_id, p.name, t.name AS type_name, p.max_length, p.is_output
FROM sys.parameters p
JOIN sys.objects o ON o.object_id = p.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types   t ON t.user_type_id = p.user_type_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_ConversionFee'
ORDER BY p.parameter_id
""")
for row in r.rows:
    print(f"  ord={row[0]} {row[1]} {row[2]}({row[3]}) is_out={row[4]}")

print()
print("=== Definition (first 80 lines) ===")
r = synapse.run("""
SELECT m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'Function_Revenue_ConversionFee'
""")
if r.rows:
    body = r.rows[0][0] or ""
    for i, ln in enumerate(body.splitlines()[:80], 1):
        print(f"  L{i:>3}: {ln}")
    print(f"  ...({len(body.splitlines())} lines total)")
