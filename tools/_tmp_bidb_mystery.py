"""Solve the BI_DB_dbo mystery:
- How many wiki .md files do we have for BI_DB_dbo?
- How many .alter.sql files exist?
- How many of those are deployable (have UC target) vs stub-only?
- How many BI_DB_dbo tables are in the generic pipeline mapping (i.e. should map to UC)?
- Which wikis exist but have NO .alter.sql AND should map to UC?
- Which BI_DB_dbo UC tables exist with NO wiki at all?
"""
from __future__ import annotations

import json
import re
from pathlib import Path

REPO = Path(".")
WIKI = REPO / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo"
GENERIC = REPO / "knowledge" / "synapse" / "Wiki" / "_generic_pipeline_mapping.json"


def main() -> None:
    # 1. Wiki files
    table_md = sorted(
        p for p in (WIKI / "Tables").glob("*.md")
        if not (".review-needed" in p.name or ".lineage" in p.name)
    )
    print(f"WIKI .md table files: {len(table_md)}")

    func_md = sorted(
        p for p in (WIKI / "Functions").glob("*.md")
        if not (".review-needed" in p.name or ".lineage" in p.name)
    )
    print(f"WIKI .md function files: {len(func_md)}")

    view_md = []
    if (WIKI / "Views").is_dir():
        view_md = sorted(
            p for p in (WIKI / "Views").glob("*.md")
            if not (".review-needed" in p.name or ".lineage" in p.name)
        )
    print(f"WIKI .md view files: {len(view_md)}")

    proc_md = []
    if (WIKI / "StoredProcedures").is_dir():
        proc_md = sorted(p for p in (WIKI / "StoredProcedures").glob("*.md"))
    print(f"WIKI .md SP files: {len(proc_md)}")

    print()

    # 2. Alter files
    alters = sorted(WIKI.rglob("*.alter.sql"))
    deployable_alters = []
    stub_alters = []
    for a in alters:
        head = a.read_text(encoding="utf-8", errors="replace")[:500]
        if "_Not_Migrated" in head or "no UC target" in head.lower():
            stub_alters.append(a)
        else:
            deployable_alters.append(a)
    print(f"ALTER files total: {len(alters)}")
    print(f"  - deployable (has UC target): {len(deployable_alters)}")
    print(f"  - stub-only (no UC target):  {len(stub_alters)}")
    print()

    # 3. Generic mapping — but BI_DB_dbo isn't in mapping (it's a Synapse DWH database, not a Tier 1 source).
    # The mapping is for bronze sources. BI_DB_dbo objects are gold pipeline targets.
    mapping = json.loads(GENERIC.read_text(encoding="utf-8"))["mappings"]
    bidb_in_mapping = [m for m in mapping if m.get("database_name") == "BI_DB"]
    print(
        f"Generic pipeline mapping rows where database='BI_DB': {len(bidb_in_mapping)}"
    )
    if bidb_in_mapping:
        for m in bidb_in_mapping[:5]:
            print(f"  example: {m['schema_name']}.{m['table_name']} -> {m['uc_table']}")
    print()

    # 4. Which wikis are deployable (have .alter.sql with UC target)?
    deployable_stems = {a.name.removesuffix(".alter.sql") for a in deployable_alters}
    md_stems = {p.stem for p in table_md}
    not_deployable_wikis = sorted(md_stems - deployable_stems)
    print(
        f"Wiki tables WITHOUT a deployable .alter.sql: {len(not_deployable_wikis)} (out of {len(md_stems)})"
    )
    print(f"  first 20: {not_deployable_wikis[:20]}")
    print()

    # 5. The 24 deployed: do they cover the 24 hottest tables, or random?
    print("Deployable .alter.sql wikis (these have UC targets):")
    for s in sorted(deployable_stems):
        print(f"  {s}")


if __name__ == "__main__":
    main()
