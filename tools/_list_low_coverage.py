"""Extract LOW_COL_COVERAGE rows from the repo-wide audit CSV.

These are tables where some columns are commented but coverage is below the
audit threshold (default 80%). Backfilling them is safe and idempotent
(--cols-only mode — table comment is preserved).
"""
import csv
import json
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ROWS = list(csv.DictReader(open(REPO / "tools/lakebridge/wiki_vs_uc_all_sources.csv", encoding="utf-8")))

low = [r for r in ROWS if r["bucket"] == "LOW_COL_COVERAGE"]
print(f"LOW_COL_COVERAGE rows: {len(low)}")

by_uc: dict[str, dict] = {}
for r in sorted(low, key=lambda x: (0 if x["source"] == "PRODSCHEMAS" else 1)):
    uc = r["uc_target"]
    if uc and uc not in by_uc:
        by_uc[uc] = r

print(f"Distinct UC targets: {len(by_uc)}")

targets = []
for uc, r in sorted(by_uc.items(), key=lambda x: -int(x[1]["uc_total_cols"])):
    targets.append({
        "wiki_md": r["wiki_md"],
        "uc_target": uc,
        "source": r["source"],
        "db": r["db"],
        "schema": r["schema"],
        "table": r["table"],
        "uc_total_cols": int(r["uc_total_cols"]),
        "uc_commented_cols": int(r.get("uc_commented_cols", 0)),
    })
out = REPO / "tools/lakebridge/low_coverage_targets.json"
out.write_text(json.dumps(targets, indent=2), encoding="utf-8")
print(f"Wrote {out.relative_to(REPO).as_posix()} ({len(targets)})\n")

by_db = defaultdict(list)
for t in targets:
    by_db[t["db"] or f"({t['source']})"].append(t)
for db, items in sorted(by_db.items(), key=lambda x: -len(x[1])):
    total_cols = sum(t["uc_total_cols"] for t in items)
    total_uncommented = sum(t["uc_total_cols"] - t["uc_commented_cols"] for t in items)
    print(f"-- {db} ({len(items)} targets, {total_uncommented}/{total_cols} cols still uncommented)")
    for t in sorted(items, key=lambda x: -(x["uc_total_cols"] - x["uc_commented_cols"])):
        gap = t["uc_total_cols"] - t["uc_commented_cols"]
        print(f"   [{t['uc_commented_cols']:>3}/{t['uc_total_cols']:<3} = gap {gap:>3}] {t['uc_target']}")
    print()
