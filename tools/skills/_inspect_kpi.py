import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

for label, path in [
    ("etoro_kpi", ROOT / "knowledge" / "skills" / "_edges_kpi.csv"),
    ("etoro_kpi_prep", ROOT / "knowledge" / "skills" / "_edges_kpi_prep.csv"),
]:
    print(f"=== {label} ===")
    with path.open("r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    print(f"Total: {len(rows)}")
    deg = Counter()
    for r in rows:
        deg[r["left"]] += 1
        deg[r["right"]] += 1
    print(f"Top 15 nodes:")
    for n, c in deg.most_common(15):
        print(f"  {c:4} {n}")
    print(f"Sample edges:")
    for r in rows[:8]:
        print(f"  {r['left']} -> {r['right']}")
    print()

idx = json.loads((ROOT / "knowledge" / "skills" / "_kpi_views_index.json").read_text(encoding="utf-8"))
print(f"=== view index ===")
print(f"Total views: {len(idx)}")
print(f"Avg refs/view: {sum(len(v['refs']) for v in idx) / max(len(idx),1):.1f}")
print(f"Top 10 most-connected views:")
for v in sorted(idx, key=lambda x: -len(x["refs"]))[:10]:
    print(f"  {len(v['refs']):3} refs  {v['self_ref']}")

print()
print("Sample view + refs:")
for v in idx[:3]:
    print(f"  {v['self_ref']} ({v['ddl_chars']} chars)")
    for r in v["refs"][:6]:
        print(f"    -> {r}")
