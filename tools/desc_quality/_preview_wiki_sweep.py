"""Show the actual diff (line-by-line) for selected wiki files."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sweep_creditbureau_wikis import transform_text

ROOT = Path(__file__).resolve().parents[2]

TARGETS = [
    "knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md",
    "knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Customer_Periodic_Status.md",
    "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_OptionsPlatform.md",
    "knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DailyCommisionReport_Instrument_Agg.md",
]

for rel in TARGETS:
    p = ROOT / rel
    raw = p.read_text(encoding="utf-8")
    new, _ = transform_text(raw)
    print("=" * 110)
    print(rel)
    print("=" * 110)
    diffs_shown = 0
    for i, (a, b) in enumerate(zip(raw.splitlines(), new.splitlines())):
        if a != b:
            diffs_shown += 1
            print(f"\n  Line {i+1}:")
            print(f"    OLD: {a}")
            print(f"    NEW: {b}")
            if diffs_shown >= 6:
                print("    ... (truncating after 6 diffs in this file)")
                break
    print()
