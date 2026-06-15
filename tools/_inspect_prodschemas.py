import json
from pathlib import Path
from collections import Counter

m = json.loads(Path("knowledge/synapse/Wiki/_generic_pipeline_mapping.json").read_text(encoding="utf-8"))["mappings"]
fiat = [x for x in m if x.get("database_name") == "FiatDwhDB"]
print(f"FiatDwhDB mappings: {len(fiat)}")
for x in fiat[:8]:
    print(f"  {x.get('schema_name','')}.{x.get('table_name',''):40} -> {x.get('uc_table','')}")
print()
print("Distinct catalogs in mapping uc_tables:")
cats = Counter(x.get("uc_table", "").split(".")[0] for x in m if x.get("uc_table"))
print(dict(cats))
print()
# Also count what ProdSchemas folders provide
prod = Path("knowledge/ProdSchemas")
db_counts = Counter()
for db_dir in prod.rglob("Wiki"):
    if not db_dir.is_dir():
        continue
    # parent = the DB name
    db = db_dir.parent.name
    # count actual table/view MDs (skip _glossary, _index, Stored Procedures)
    md_count = 0
    for md in db_dir.rglob("*.md"):
        if md.name.startswith("_"):
            continue
        rel = md.relative_to(db_dir)
        if any(p == "Stored Procedures" or p == "User Defined Types" for p in rel.parts):
            continue
        md_count += 1
    db_counts[db] = md_count
print("ProdSchemas wiki MD counts per DB (excluding _* and Stored Procedures/UDTs):")
for db, n in db_counts.most_common():
    print(f"  {db:<30} {n:>5}")
print(f"  TOTAL: {sum(db_counts.values())}")
