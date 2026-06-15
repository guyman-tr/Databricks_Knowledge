"""Print the full Synapse SP block from L1500 -> end of Options reinsert."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE s.name = 'BI_DB_dbo' AND o.name = 'SP_DDR_Fact_Revenue_Generating_Actions'
""")
defn = r.rows[0][0]
lines = defn.splitlines()
# Print L1380 (before Options TVF call) -> L1660 (end of options block)
for i in range(1380, min(1660, len(lines))):
    print(f"L{i+1:4d}: {lines[i]}")
