"""Pull the Synapse SP STEP 3 (Staking) section so we can compare line-for-line."""
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

# Phase 1 of staking: production, sees both the build into #revenue and the final delete-insert
# We saw earlier the build at L1390 (FROM Function_Revenue_StakingFee), and the delete at L1637.
# Print L1340-1400 (#revenue build) and L1635-1750 (final delete-insert + group-by)
print("=== Synapse SP — staking build into #revenue (around L1340-1400) ===")
for i in range(1335, min(1400, len(lines))):
    print(f"L{i+1:4d}: {lines[i]}")

print()
print("=== Synapse SP — final staking delete + insert (L1635 onwards) ===")
for i in range(1635, min(1760, len(lines))):
    print(f"L{i+1:4d}: {lines[i]}")
