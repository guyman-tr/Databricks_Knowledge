#!/usr/bin/env python3
"""
Phase 0 — Global upstream-wiki index builder (UC-Pipeline pack).

Walks every wiki tree in the repo ONCE and produces a single shared index that
maps `main.{schema}.{name}` → wiki path. Downstream phases hit this index in
O(1) instead of re-scanning directories per schema run.

Trees walked:
  - `knowledge/synapse/Wiki/{Schema}/{Tables|Views|Functions}/{Name}.md`
    → derived UC name `main.dwh.gold_sql_dp_prod_we_{snake_schema}_{snake_name}`
      (the Synapse-mirror UC convention used by the Generic Pipeline).
  - `knowledge/UC_generated/{schema}/{Tables|Views}/{Name}.md`
    → `main.{schema}.{Name}` (case as authored).
  - `knowledge/uc_domains/{domain}/schemas/{schema}/{Tables|Views}/{Name}.md`
    → `main.{schema}.{Name}`.

The output is cache-only — running it twice produces the same bytes. Re-run
before any pipeline run to pick up wikis that were added since the last run.

Output: `knowledge/UC_generated/_upstream_wiki_index.json`

Usage:
  python tools/uc_pipelines/build_upstream_wiki_index.py
"""
from __future__ import annotations

import datetime as dt
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SYNAPSE_WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"
UC_GENERATED_ROOT = REPO / "knowledge" / "UC_generated"
UC_DOMAIN_ROOT = REPO / "knowledge" / "uc_domains"
PROD_SCHEMAS_ROOT = REPO / "knowledge" / "ProdSchemas"
ROUTING_PATH = SYNAPSE_WIKI_ROOT / "_upstream_wiki_routing.json"
PIPELINE_MAPPING_PATH = SYNAPSE_WIKI_ROOT / "_generic_pipeline_mapping.json"
OUT_PATH = UC_GENERATED_ROOT / "_upstream_wiki_index.json"

SYNAPSE_SCHEMA_TO_SNAKE = {
    "DWH_dbo": "dwh_dbo",
    "BI_DB_dbo": "bi_db_dbo",
    "Dealing_dbo": "dealing_dbo",
    "eMoney_dbo": "emoney_dbo",
    "EXW_dbo": "exw_dbo",
    "EXW_Wallet": "exw_wallet",
    "eMoney_Tribe": "emoney_tribe",
}


def _is_real_wiki(p: Path) -> bool:
    n = p.name
    if not n.endswith(".md"):
        return False
    if n.endswith(".lineage.md") or n.endswith(".review-needed.md") or n.endswith(".alter.sql"):
        return False
    if n.startswith("_"):
        return False
    return True


def _camel_to_snake(s: str) -> str:
    s1 = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", s)
    s2 = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s1)
    return s2.lower()


def _count_columns(md_path: Path) -> int | None:
    try:
        text = md_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if m:
        try:
            import yaml  # type: ignore
            fm = yaml.safe_load(m.group(1)) or {}
            if isinstance(fm.get("column_count"), int):
                return fm["column_count"]
        except Exception:
            pass
    sec = re.search(
        r"^##\s+3\.\s+(?:Elements|Columns)\b(.*?)(?=^##\s+\d+\.\s|\Z)",
        text, flags=re.IGNORECASE | re.MULTILINE | re.DOTALL,
    )
    if not sec:
        sec = re.search(
            r"^##\s+(?:Elements|Columns)\b(.*?)(?=^##\s+\d+\.\s|^##\s+[A-Z]|\Z)",
            text, flags=re.IGNORECASE | re.MULTILINE | re.DOTALL,
        )
    if not sec:
        return None
    count = 0
    for line in sec.group(1).splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if not cells or not cells[0].isdigit():
            continue
        count += 1
    return count or None


def scan_synapse() -> list[dict]:
    entries: list[dict] = []
    if not SYNAPSE_WIKI_ROOT.is_dir():
        return entries
    for schema_dir in sorted(SYNAPSE_WIKI_ROOT.iterdir()):
        if not schema_dir.is_dir():
            continue
        snake_schema = SYNAPSE_SCHEMA_TO_SNAKE.get(schema_dir.name)
        if not snake_schema:
            continue
        for folder in ("Tables", "Views", "Functions"):
            d = schema_dir / folder
            if not d.is_dir():
                continue
            for md in sorted(d.glob("*.md")):
                if not _is_real_wiki(md):
                    continue
                table_name = md.stem
                snake_table = _camel_to_snake(table_name)
                uc_name = f"main.dwh.gold_sql_dp_prod_we_{snake_schema}_{snake_table}"
                entries.append({
                    "full_name": uc_name,
                    "wiki_path": str(md.relative_to(REPO)).replace("\\", "/"),
                    "wiki_kind": "synapse_mirror",
                    "synapse_schema": schema_dir.name,
                    "synapse_object": table_name,
                    "synapse_folder": folder,
                    "column_count": _count_columns(md),
                })
    return entries


def scan_uc_generated() -> list[dict]:
    entries: list[dict] = []
    if not UC_GENERATED_ROOT.is_dir():
        return entries
    for schema_dir in sorted(UC_GENERATED_ROOT.iterdir()):
        if not schema_dir.is_dir() or schema_dir.name.startswith("_"):
            continue
        schema = schema_dir.name
        for folder in ("Tables", "Views"):
            d = schema_dir / folder
            if not d.is_dir():
                continue
            for md in sorted(d.glob("*.md")):
                if not _is_real_wiki(md):
                    continue
                name = md.stem
                entries.append({
                    "full_name": f"main.{schema}.{name}".lower(),
                    "wiki_path": str(md.relative_to(REPO)).replace("\\", "/"),
                    "wiki_kind": "uc_generated",
                    "schema": schema,
                    "uc_folder": folder,
                    "column_count": _count_columns(md),
                })
    return entries


def scan_uc_domains() -> list[dict]:
    entries: list[dict] = []
    if not UC_DOMAIN_ROOT.is_dir():
        return entries
    for domain_dir in sorted(UC_DOMAIN_ROOT.iterdir()):
        if not domain_dir.is_dir():
            continue
        schemas_root = domain_dir / "schemas"
        if not schemas_root.is_dir():
            continue
        for schema_dir in sorted(schemas_root.iterdir()):
            if not schema_dir.is_dir():
                continue
            for folder in ("Tables", "Views"):
                d = schema_dir / folder
                if not d.is_dir():
                    continue
                for md in sorted(d.glob("*.md")):
                    if not _is_real_wiki(md):
                        continue
                    name = md.stem
                    entries.append({
                        "full_name": f"main.{schema_dir.name}.{name}".lower(),
                        "wiki_path": str(md.relative_to(REPO)).replace("\\", "/"),
                        "wiki_kind": "uc_domain",
                        "domain": domain_dir.name,
                        "schema": schema_dir.name,
                        "uc_folder": folder,
                        "column_count": _count_columns(md),
                    })
    return entries


def scan_bronze_tier1() -> list[dict]:
    """Index Tier 1 wikis from sibling-repo databases (vendored under knowledge/ProdSchemas/).

    Uses _generic_pipeline_mapping.json (database/schema/table → uc_table) and
    _upstream_wiki_routing.json (database → repo_path + wiki_path) to derive the
    on-disk wiki path for each mapping row. Only emits entries where the wiki
    actually exists on disk."""
    entries: list[dict] = []
    if not ROUTING_PATH.is_file() or not PIPELINE_MAPPING_PATH.is_file():
        return entries
    try:
        routing = json.loads(ROUTING_PATH.read_text(encoding="utf-8"))
        mapping = json.loads(PIPELINE_MAPPING_PATH.read_text(encoding="utf-8"))
    except Exception:
        return entries
    upstream_dbs = routing.get("upstream_databases") or {}

    for row in mapping.get("mappings", []) or []:
        db = row.get("database_name") or ""
        schema = row.get("schema_name") or ""
        table = row.get("table_name") or ""
        uc_short = row.get("uc_table") or ""
        if not (db and schema and table and uc_short):
            continue
        route = upstream_dbs.get(db)
        if not route:
            continue
        repo_path = Path(route.get("repo_path") or "")
        wiki_path = (route.get("wiki_path") or "").replace("\\", "/")
        if not repo_path.is_dir() or not wiki_path:
            continue
        base = repo_path / wiki_path / schema
        # Prefer Tables, fall back to Views (matches the upstream-wiki-router skill rules).
        cand_table = base / "Tables" / f"{schema}.{table}.md"
        cand_view = base / "Views" / f"{schema}.{table}.md"
        if cand_table.is_file():
            md = cand_table
            folder = "Tables"
        elif cand_view.is_file():
            md = cand_view
            folder = "Views"
        else:
            continue
        if not _is_real_wiki(md):
            continue
        full_name = f"main.{uc_short}".lower()
        # Lake path is informational but useful for downstream resolvers.
        lake = (row.get("datalake_path") or "").rstrip("/")
        entries.append({
            "full_name": full_name,
            "wiki_path": str(md.relative_to(REPO)).replace("\\", "/"),
            "wiki_kind": "bronze_tier1",
            "source_database": db,
            "source_schema": schema,
            "source_table": table,
            "source_repo": route.get("repo"),
            "source_folder": folder,
            "datalake_path": lake or None,
            "copy_strategy": row.get("copy_strategy"),
            "business_group": row.get("business_group"),
            "column_count": _count_columns(md),
        })
    return entries


def main() -> int:
    syn = scan_synapse()
    uc_g = scan_uc_generated()
    uc_d = scan_uc_domains()
    bronze = scan_bronze_tier1()

    all_entries = syn + uc_g + uc_d + bronze
    wikis: dict[str, dict] = {}
    duplicates: list[str] = []
    for e in all_entries:
        fn = e["full_name"]
        if fn in wikis:
            duplicates.append(fn)
            continue
        wikis[fn] = e

    stats = {
        "total": len(wikis),
        "synapse_mirror": sum(1 for v in wikis.values() if v["wiki_kind"] == "synapse_mirror"),
        "uc_generated": sum(1 for v in wikis.values() if v["wiki_kind"] == "uc_generated"),
        "uc_domain": sum(1 for v in wikis.values() if v["wiki_kind"] == "uc_domain"),
        "bronze_tier1": sum(1 for v in wikis.values() if v["wiki_kind"] == "bronze_tier1"),
        "duplicates_dropped": len(duplicates),
    }

    payload = {
        "framework": "uc-pipeline-doc",
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "wikis": wikis,
        "stats": stats,
        "duplicates": duplicates[:50],
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[upstream-wiki-index] wrote {OUT_PATH.relative_to(REPO)}")
    print(f"[upstream-wiki-index] stats={stats}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
