"""Dump the REMOVE_BAD_FTDS CTE from both bidev functions to confirm deploy state."""
import sys, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from synapse_connect import connect

c = connect(verbose=False)
cur = c.cursor()

for fn in ("Function_Population_First_Time_Funded", "Function_MIMO_First_Deposit_All_Platforms"):
    print(f"\n{'=' * 70}\n{fn}\n{'=' * 70}")
    cur.execute(
        "SELECT definition, modify_date FROM sys.sql_modules m "
        "JOIN sys.objects o ON o.object_id = m.object_id "
        "WHERE o.name = ?", fn)
    row = cur.fetchone()
    if not row or not row[0]:
        print("  (definition unreadable - permission issue)")
        continue
    defn, mod = row
    print(f"  modify_date: {mod}")
    print(f"  total length: {len(defn):,} chars")
    m = re.search(r"REMOVE_BAD_FTDS[^,]*\)\s*,", defn, re.DOTALL)
    if m:
        snippet = m.group(0)
        if len(snippet) > 2000:
            snippet = snippet[:2000] + "\n... (truncated)"
        print("\n--- REMOVE_BAD_FTDS CTE ---\n" + snippet)
    else:
        print("  WARN: REMOVE_BAD_FTDS not found")
    # Check for new dates
    for d in ("20260522", "20260523", "20260525", "20250818"):
        print(f"  contains '{d}': {d in defn}")

c.close()
