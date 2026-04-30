"""Build the UC bronze ALTER scope by joining the Generic Pipeline mapping
with the synced Tier 1 wikis under knowledge/ProdSchemas/.

Inputs:
  knowledge/synapse/Wiki/_generic_pipeline_mapping.json   (1,711 mappings)
  knowledge/synapse/Wiki/_upstream_wiki_routing.json      (15 synced dbs)

Output:
  knowledge/ProdSchemas/_bronze_scope.json

For each mapping row we resolve a candidate wiki path
({wiki_root}/{schema}/Tables/{schema}.{table}.md) and assign a status:

  ready              wiki file exists at exact path
  ready_case_match   wiki file resolved via case-insensitive lookup
  no_wiki_file       db is synced, schema/table file not found
  no_wiki_db         db is not in the synced ProdSchemas tree
  third_party        database_name flagged as Fivetran/Rivery/etc. (no PROD wiki by design)

Status counts and per-database breakdown are written to the scope's _summary.

Usage:
  python -m tools.uc_bronze.build_bronze_scope                    # write scope
  python -m tools.uc_bronze.build_bronze_scope --dry-run          # print summary only
  python -m tools.uc_bronze.build_bronze_scope --db FiatDwhDB     # filter
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MAPPING_FILE = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_generic_pipeline_mapping.json"
ROUTING_FILE = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_upstream_wiki_routing.json"
PRODSCHEMAS_DIR = REPO_ROOT / "knowledge" / "ProdSchemas"
SCOPE_FILE = PRODSCHEMAS_DIR / "_bronze_scope.json"

THIRD_PARTY_DBS = {"Fivetran", "Rivery"}


def load_json(p: Path) -> dict:
    with p.open(encoding="utf-8") as fh:
        return json.load(fh)


def build_case_index(wiki_root: Path) -> dict[tuple[str, str], Path]:
    """Index every wiki file under wiki_root by (schema_lower, file_stem_lower).

    file_stem is the markdown filename without the .md extension. Tier 1 wikis
    use the convention '{schema}.{table_name}.md', so file_stem will be
    '{schema}.{table_name}' (case as found on disk).
    """
    out: dict[tuple[str, str], Path] = {}
    if not wiki_root.is_dir():
        return out
    for md in wiki_root.rglob("*.md"):
        try:
            rel = md.relative_to(wiki_root)
        except ValueError:
            continue
        parts = rel.parts
        if len(parts) < 2:
            continue
        schema = parts[0]
        stem = md.stem
        out[(schema.lower(), stem.lower())] = md
    return out


def resolve_wiki_path(
    wiki_root: Path,
    schema: str,
    table: str,
    case_index: dict[tuple[str, str], Path],
) -> tuple[str, Path | None, str]:
    """Try exact path first, then case-insensitive index lookup.

    Returns (status, resolved_path_or_None, rel_path_str).
    """
    exact = wiki_root / schema / "Tables" / f"{schema}.{table}.md"
    if exact.is_file():
        return "ready", exact, str(exact.relative_to(REPO_ROOT)).replace("\\", "/")
    stem_lower = f"{schema}.{table}".lower()
    hit = case_index.get((schema.lower(), stem_lower))
    if hit is not None:
        return "ready_case_match", hit, str(hit.relative_to(REPO_ROOT)).replace("\\", "/")
    return "no_wiki_file", None, ""


def build_scope(only_db: str | None = None) -> dict:
    if not MAPPING_FILE.is_file():
        sys.exit(f"FATAL: missing mapping file {MAPPING_FILE}")
    if not ROUTING_FILE.is_file():
        sys.exit(f"FATAL: missing routing file {ROUTING_FILE}")

    mapping_doc = load_json(MAPPING_FILE)
    routing_doc = load_json(ROUTING_FILE)

    upstream = routing_doc.get("upstream_databases", {})
    case_indexes: dict[str, dict[tuple[str, str], Path]] = {}
    wiki_roots: dict[str, Path] = {}
    for db_name, info in upstream.items():
        wpath = info.get("wiki_path")
        if not wpath:
            continue
        wiki_root = REPO_ROOT / wpath
        wiki_roots[db_name] = wiki_root
        case_indexes[db_name] = build_case_index(wiki_root)

    rows: list[dict] = []
    status_counter: Counter[str] = Counter()
    db_status: dict[str, Counter[str]] = defaultdict(Counter)

    for entry in mapping_doc.get("mappings", []):
        db = (entry.get("database_name") or "").strip()
        schema = (entry.get("schema_name") or "").strip()
        table = (entry.get("table_name") or "").strip()
        uc_table = (entry.get("uc_table") or "").strip()

        if only_db and db != only_db:
            continue

        if not db or not schema or not table or not uc_table:
            status = "missing_fields"
            row = _row(entry, status, "", "")
            rows.append(row)
            status_counter[status] += 1
            db_status[db or "<missing>"][status] += 1
            continue

        if db in THIRD_PARTY_DBS:
            status = "third_party"
            row = _row(entry, status, "", "")
            rows.append(row)
            status_counter[status] += 1
            db_status[db][status] += 1
            continue

        if db not in wiki_roots:
            status = "no_wiki_db"
            row = _row(entry, status, "", "")
            rows.append(row)
            status_counter[status] += 1
            db_status[db][status] += 1
            continue

        status, _resolved, rel_path = resolve_wiki_path(
            wiki_roots[db], schema, table, case_indexes[db]
        )
        row = _row(entry, status, rel_path, str(wiki_roots[db].relative_to(REPO_ROOT)).replace("\\", "/"))
        rows.append(row)
        status_counter[status] += 1
        db_status[db][status] += 1

    summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "tool": "tools/uc_bronze/build_bronze_scope.py",
        "mapping_source": str(MAPPING_FILE.relative_to(REPO_ROOT)).replace("\\", "/"),
        "routing_source": str(ROUTING_FILE.relative_to(REPO_ROOT)).replace("\\", "/"),
        "filter_db": only_db,
        "total_rows": len(rows),
        "status_counts": dict(status_counter.most_common()),
        "by_database": {
            db: dict(c.most_common()) for db, c in sorted(db_status.items())
        },
    }
    return {"_summary": summary, "rows": rows}


def _row(entry: dict, status: str, wiki_rel_path: str, wiki_root_rel: str) -> dict:
    return {
        "status": status,
        "uc_table": entry.get("uc_table", ""),
        "business_group": entry.get("business_group", ""),
        "database_name": entry.get("database_name", ""),
        "schema_name": entry.get("schema_name", ""),
        "table_name": entry.get("table_name", ""),
        "copy_strategy": entry.get("copy_strategy", ""),
        "frequency_minutes": entry.get("frequency_minutes", ""),
        "datalake_path": entry.get("datalake_path", ""),
        "wiki_root": wiki_root_rel,
        "wiki_path": wiki_rel_path,
        "generic_id": entry.get("generic_id", ""),
    }


def print_summary(summary: dict) -> None:
    print(f"\nUC bronze scope summary  (generated {summary['generated_at']})")
    print(f"  mapping rows : {summary['total_rows']}")
    if summary.get("filter_db"):
        print(f"  filter db    : {summary['filter_db']}")
    print(f"\n  status counts:")
    for k, v in summary["status_counts"].items():
        print(f"    {k:<22} {v:>5}")
    print(f"\n  per-database (top 25):")
    items = list(summary["by_database"].items())
    items.sort(key=lambda kv: -sum(kv[1].values()))
    for db, c in items[:25]:
        ready = c.get("ready", 0) + c.get("ready_case_match", 0)
        total = sum(c.values())
        print(f"    {db:<28} ready={ready:>4}  total={total:>4}  detail={dict(c)}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--db", default=None, help="Filter to one database_name (e.g. FiatDwhDB)")
    ap.add_argument("--dry-run", action="store_true", help="Print summary, don't write file")
    ap.add_argument("--out", default=str(SCOPE_FILE), help="Output path (defaults to knowledge/ProdSchemas/_bronze_scope.json)")
    args = ap.parse_args()

    scope = build_scope(only_db=args.db)
    print_summary(scope["_summary"])

    if args.dry_run:
        print("\n(dry-run: scope file NOT written)")
        return 0

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(scope, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nWrote scope: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
