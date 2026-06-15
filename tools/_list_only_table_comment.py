"""Extract ONLY_TABLE_COMMENT rows from the repo-wide audit CSV.

These are tables where UC already has a table-level comment but the columns
are entirely uncommented — perfect candidates for a --cols-only backfill
that leaves the existing table comment alone.
"""
import csv
import json
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ROWS = list(csv.DictReader(open(REPO / "tools/lakebridge/wiki_vs_uc_all_sources.csv", encoding="utf-8")))
only_tc = [r for r in ROWS if r["bucket"] == "ONLY_TABLE_COMMENT"]
print(f"ONLY_TABLE_COMMENT rows: {len(only_tc)}")

# Dedupe by UC target — prefer ProdSchemas wikis (richer)
by_uc: dict[str, dict] = {}
for r in sorted(only_tc, key=lambda x: (0 if x["source"] == "PRODSCHEMAS" else 1)):
    uc = r["uc_target"]
    if uc and uc not in by_uc:
        by_uc[uc] = r

print(f"Distinct UC targets: {len(by_uc)}")
print()

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
    })
out = REPO / "tools/lakebridge/only_table_comment_targets.json"
out.write_text(json.dumps(targets, indent=2), encoding="utf-8")
print(f"Wrote {out.relative_to(REPO).as_posix()} ({len(targets)})")

# Group preview by db
by_db = defaultdict(list)
for t in targets:
    by_db[t["db"] or f"({t['source']})"].append(t)
for db, items in sorted(by_db.items(), key=lambda x: -len(x[1])):
    print(f"\n-- {db} ({len(items)} targets)")
    for t in sorted(items, key=lambda x: -x["uc_total_cols"]):
        print(f"   [{t['uc_total_cols']:>3} cols] {t['uc_target']:<70} <- {t['wiki_md']}")
