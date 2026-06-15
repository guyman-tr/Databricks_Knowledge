"""Phase 1 summary helper - splits overlaps by source field and surfaces a
checkpoint-ready report.
"""
from __future__ import annotations

import csv
import sys
from collections import Counter
from pathlib import Path

INVENTORY = Path(sys.argv[1]) if len(sys.argv) > 1 else None
if INVENTORY is None or not INVENTORY.is_dir():
    print("usage: _summarize.py <path-to-inventory-folder>")
    sys.exit(1)

concepts_csv = INVENTORY / "concepts.csv"

rows = list(csv.DictReader(concepts_csv.open(encoding="utf-8")))
print(f"Total normalized concepts: {len(rows)}")
print()

# Bucket by source-field composition + hub count
by_field: Counter = Counter()
overlap_by_field: Counter = Counter()
hub_count_dist: Counter = Counter()
for r in rows:
    fields = tuple(sorted(r["source_fields"].split("; ")))
    hub_count = int(r["hub_count"])
    by_field[fields] += 1
    hub_count_dist[hub_count] += 1
    if hub_count >= 2:
        overlap_by_field[fields] += 1

print("Source-field composition (all concepts):")
for fields, n in by_field.most_common():
    print(f"  {fields}: {n}")
print()

print("Source-field composition (OVERLAPPING concepts, hub_count >= 2):")
for fields, n in overlap_by_field.most_common():
    print(f"  {fields}: {n}")
print()

print("Hub-count distribution:")
for hc in sorted(hub_count_dist.keys()):
    print(f"  {hc} hub(s): {hub_count_dist[hc]}")
print()

# Trigger-only overlaps (the real routing problem)
trigger_only_overlaps = [
    r for r in rows
    if r["source_fields"] == "triggers" and int(r["hub_count"]) >= 2
]
print(f"TRIGGER-ONLY overlapping concepts (the real routing problem): {len(trigger_only_overlaps)}")
print()
print("Top 50 trigger-only overlaps:")
trigger_only_sorted = sorted(
    trigger_only_overlaps,
    key=lambda r: (-int(r["hub_count"]), r["normalized_concept"]),
)
for r in trigger_only_sorted[:50]:
    print(f"  [{r['hub_count']}] {r['normalized_concept']:<45} <-  {r['claiming_hubs']}")
print()

# Mixed: appears as trigger on at least one hub AND has multi-hub overlap
mixed_with_trigger = [
    r for r in rows
    if "triggers" in r["source_fields"].split("; ")
    and int(r["hub_count"]) >= 2
]
print(f"Overlapping concepts where AT LEAST ONE hub has it as a trigger: {len(mixed_with_trigger)}")
