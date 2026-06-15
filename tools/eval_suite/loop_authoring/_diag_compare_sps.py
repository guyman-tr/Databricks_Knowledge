"""Pull Synapse SP_DDR_Fact_Revenue_Generating_Actions and dump its Options branch."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

print("=== Locate the Synapse SP ===")
r = synapse.run("""
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc, m.uses_ansi_nulls, m.uses_quoted_identifier
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.name LIKE 'SP_DDR_Fact_Revenue_Generating_Actions%'
   OR o.name LIKE 'SP_BI_DB_DDR_Fact_Revenue%'
""")
for row in r.rows:
    print(f"  {row[0]}.{row[1]}  type={row[2]}")

print()
print("=== Pull the SP body ===")
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.name LIKE 'SP_DDR_Fact_Revenue_Generating_Actions%'
   OR o.name LIKE 'SP_BI_DB_DDR_Fact_Revenue%'
""")
if not r.rows:
    print("  no SP found")
    sys.exit(1)

defn = r.rows[0][0]
print(f"  body chars: {len(defn)}")

import re
# Look for Options-related blocks
print()
print("=== Options-related blocks in Synapse SP ===")
# Find lines mentioning Options, RevenueMetricID = 18, Options_PFOF, OptionsPlatform
patterns = [r'Options_PFOF', r'OptionsPlatform', r'RevenueMetricID\s*=\s*18', r'-- *.*Options', r'-- *STEP', r'/\*.*Options']
hits = []
for i, ln in enumerate(defn.splitlines()):
    for p in patterns:
        if re.search(p, ln, re.IGNORECASE):
            hits.append((i + 1, ln.rstrip()))
            break

# Print a window around each hit, dedupe overlapping
shown = set()
for ln_no, _ in hits:
    if ln_no in shown:
        continue
    start = max(1, ln_no - 3)
    end = min(len(defn.splitlines()), ln_no + 12)
    lines = defn.splitlines()
    print(f"\n  --- L{start}-L{end} ---")
    for i in range(start - 1, end):
        marker = ">>>" if (i + 1) == ln_no else "   "
        print(f"  {marker} L{i+1:4d}: {lines[i].rstrip()}")
    for k in range(start, end + 1):
        shown.add(k)

print()
print("=== All 'FROM <object>' clauses to map data sources ===")
froms = re.findall(r'(?:FROM|JOIN)\s+([A-Za-z0-9_\[\]\.]+)', defn, re.IGNORECASE)
for s in sorted(set(froms)):
    print(f"  {s}")
