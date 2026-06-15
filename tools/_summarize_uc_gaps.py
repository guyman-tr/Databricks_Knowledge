"""Group the audit results by source DB / UC schema so triage is concrete."""
import csv
from collections import Counter, defaultdict
from pathlib import Path

rows = list(csv.DictReader(open("tools/lakebridge/wiki_vs_uc_all_sources.csv", encoding="utf-8")))

print("=" * 80)
print("NO_COMMENTS_AT_ALL — UC table is COMPLETELY bare but has a wiki")
print("=" * 80)
bare = [r for r in rows if r["bucket"] == "NO_COMMENTS_AT_ALL"]
print(f"Total: {len(bare)} UC tables\n")

# Group by ProdSchemas source DB
by_src_db = defaultdict(list)
for r in bare:
    if r["source"] == "PRODSCHEMAS":
        by_src_db[r["db"]].append(r)
    else:
        by_src_db[f"({r['source']})"].append(r)

for db, items in sorted(by_src_db.items(), key=lambda x: -len(x[1])):
    print(f"-- {db}  ({len(items)} bare tables)")
    for r in sorted(items, key=lambda x: -int(x["uc_total_cols"])):
        print(f"   [{r['uc_total_cols']:>3} cols] {r['uc_target']:<70}")
    print()

# Also: ONLY_TABLE_COMMENT — col comments missing
only = [r for r in rows if r["bucket"] == "ONLY_TABLE_COMMENT"]
print("=" * 80)
print(f"ONLY_TABLE_COMMENT ({len(only)}) — table-level comment set, 0/N col comments")
print("=" * 80)
big_only = sorted(only, key=lambda x: -int(x["uc_total_cols"]))
for r in big_only[:25]:
    print(f"   [{r['uc_total_cols']:>3} cols] {r['uc_target']:<70} (kind={r['kind']})")
print()

# LOW_COL_COVERAGE: high col-count + low coverage
low = [r for r in rows if r["bucket"] == "LOW_COL_COVERAGE"]
print("=" * 80)
print(f"LOW_COL_COVERAGE ({len(low)}) — <30 percent of cols commented (high-impact subset shown)")
print("=" * 80)
big_low = sorted([r for r in low if int(r["uc_total_cols"]) >= 10], key=lambda x: -int(x["uc_total_cols"]))
for r in big_low[:25]:
    pct = r["uc_col_coverage_pct"]
    print(f"   [{int(r['uc_commented_cols']):>3}/{int(r['uc_total_cols']):<3} ({pct} pct)] {r['uc_target']:<70}")
print()

# MISSING_IN_UC summary
miss = [r for r in rows if r["bucket"] == "MISSING_IN_UC"]
print("=" * 80)
print(f"MISSING_IN_UC ({len(miss)}) — mapping points to UC table that does not exist")
print("=" * 80)
miss_by_db = Counter(r["db"] or "(synapse)" for r in miss)
for db, n in miss_by_db.most_common():
    print(f"   {db:<25} {n:>3}")
print()

# NOT_MAPPED summary — wiki exists but no generic mapping
nm = [r for r in rows if r["bucket"] == "NOT_MAPPED"]
print("=" * 80)
print(f"NOT_MAPPED ({len(nm)}) — wiki exists but no generic-pipeline mapping")
print("=" * 80)
print("By source:")
nm_by_src = Counter(r["source"] for r in nm)
for s, n in nm_by_src.most_common():
    print(f"   {s:<14} {n:>5}")
print()
print("Top ProdSchemas DBs with unmapped wikis (likely never landed in UC OR mapped differently):")
nm_prod_by_db = Counter(r["db"] for r in nm if r["source"] == "PRODSCHEMAS")
for db, n in nm_prod_by_db.most_common(15):
    print(f"   {db:<25} {n:>5}")
