import json
from pathlib import Path
REPO = Path(__file__).resolve().parents[1]
d = json.loads((REPO / "tools/lakebridge/low_coverage_scaffold_summary.json").read_text(encoding="utf-8"))
total = sum(s.get("paired", 0) for s in d)
nonempty = [s for s in d if s.get("paired", 0) > 0]
empty = [s for s in d if s.get("paired", 0) == 0]
print(f"Files with paired cols: {len(nonempty)} / {len(d)}")
print(f"Total column comments staged: {total}")
print()
print(f"Empties ({len(empty)}):")
for s in empty:
    print(f"   {s['wiki']:<90} -> {s['uc']}")
print()
print("Top 8 by paired-col count:")
for s in sorted(d, key=lambda x: -x.get("paired", 0))[:8]:
    print(f"   {s['paired']:>3}/{s['uc_cols']:<3}  {s['uc']}")
