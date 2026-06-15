"""Dump the trigger-only overlaps from concepts.csv as a sorted CSV for Phase 2
classification. Sort: hub_count desc, then concept asc.
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

INVENTORY = Path(sys.argv[1])
OUT = INVENTORY / "trigger_overlaps_for_classification.csv"

rows = []
with (INVENTORY / "concepts.csv").open(encoding="utf-8") as f:
    for r in csv.DictReader(f):
        if r["source_fields"] != "triggers":
            continue
        if int(r["hub_count"]) < 2:
            continue
        rows.append(r)

rows.sort(key=lambda r: (-int(r["hub_count"]), r["normalized_concept"]))

with OUT.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["concept", "hub_count", "claiming_hubs", "variants", "primary_owner", "pattern", "action_for_secondaries", "notes"])
    for r in rows:
        w.writerow([
            r["normalized_concept"],
            r["hub_count"],
            r["claiming_hubs"],
            r["variants"],
            "",
            "",
            "",
            "",
        ])

print(f"Wrote {len(rows)} rows to {OUT}")
print(f"Hub-count breakdown:")
from collections import Counter
c = Counter(int(r["hub_count"]) for r in rows)
for hc in sorted(c.keys(), reverse=True):
    print(f"  {hc} hub(s): {c[hc]}")
