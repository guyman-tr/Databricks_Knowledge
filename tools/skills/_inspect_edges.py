import csv
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
src = ROOT / "knowledge" / "skills" / "_edges_wiki.csv"

with src.open("r", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

print("Total edges:", len(rows))
print()
print("By edge_kind:")
for k, v in Counter(r["edge_kind"] for r in rows).most_common():
    print(f"  {k}: {v}")
print()
print("By schema_dir:")
for k, v in Counter(r["schema_dir"] for r in rows).most_common():
    print(f"  {k}: {v}")
print()
print("Sample lineage edges:")
for r in [r for r in rows if r["edge_kind"] == "lineage"][:8]:
    print(f"  {r['left']} -> {r['right']} via {r['join_keys'][:60]}")
print()
print("Sample common_join edges:")
for r in [r for r in rows if r["edge_kind"] == "common_join"][:8]:
    print(f"  {r['left']} -> {r['right']}: {r['join_keys'][:60]}")
print()
print("Sample references_to edges:")
for r in [r for r in rows if r["edge_kind"] == "references_to"][:8]:
    print(f"  {r['left']} -> {r['right']} via {r['join_keys']}")
print()
print("Sample referenced_by edges:")
for r in [r for r in rows if r["edge_kind"] == "referenced_by"][:8]:
    print(f"  {r['left']} -> {r['right']} via {r['join_keys']}")
print()
print("Top 25 nodes by degree:")
deg = Counter()
for r in rows:
    deg[r["left"]] += 1
    deg[r["right"]] += 1
for k, v in deg.most_common(25):
    print(f"  {k}: {v}")
print()
print("Bare-name (no schema) nodes - signal of parsing trouble. Top 20:")
bare = Counter()
for r in rows:
    for side in ("left", "right"):
        if "." not in r[side]:
            bare[r[side]] += 1
for k, v in bare.most_common(20):
    print(f"  {k}: {v}")
