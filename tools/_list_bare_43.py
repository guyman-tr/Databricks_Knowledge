"""Extract the 43 NO_COMMENTS_AT_ALL rows and write a focused targets file
that the scaffold tool will consume."""
import csv
import json
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ROWS = list(csv.DictReader(open(REPO / "tools/lakebridge/wiki_vs_uc_all_sources.csv", encoding="utf-8")))
bare = [r for r in ROWS if r["bucket"] == "NO_COMMENTS_AT_ALL"]
print(f"Bare rows: {len(bare)}")

# Deduplicate by UC target — sometimes ProdSchemas + UC_GENERATED both
# document the same UC table. Prefer ProdSchemas (richer source).
by_uc: dict[str, dict] = {}
for r in sorted(bare, key=lambda x: (0 if x["source"] == "PRODSCHEMAS" else 1)):
    uc = r["uc_target"]
    if uc and uc not in by_uc:
        by_uc[uc] = r

print(f"Distinct UC targets: {len(by_uc)}")
print()

# Write focused targets JSON
out_path = REPO / "tools/lakebridge/bare_43_targets.json"
targets = []
for uc, r in sorted(by_uc.items()):
    targets.append({
        "wiki_md": r["wiki_md"],
        "uc_target": uc,
        "source": r["source"],
        "db": r["db"],
        "schema": r["schema"],
        "table": r["table"],
        "uc_total_cols": int(r["uc_total_cols"]),
    })
out_path.write_text(json.dumps(targets, indent=2), encoding="utf-8")
print(f"Wrote {out_path.relative_to(REPO).as_posix()} ({len(targets)} targets)")

# Group preview
by_grp = defaultdict(list)
for t in targets:
    grp = t["db"] if t["db"] else f"({t['source']})"
    by_grp[grp].append(t)
for grp, items in sorted(by_grp.items(), key=lambda x: -len(x[1])):
    print(f"\n-- {grp} ({len(items)} targets)")
    for t in sorted(items, key=lambda x: -x["uc_total_cols"]):
        print(f"   [{t['uc_total_cols']:>3} cols] {t['uc_target']:<70} <- {t['wiki_md']}")
