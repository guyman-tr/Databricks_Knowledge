#!/usr/bin/env python3
"""
Phase 3 — Upstream Wiki Bridge (UC-Pipeline pack).

For each UC object surfaced as an upstream of the in-scope objects of a schema,
locate its existing wiki (Synapse mirror / sibling UC_generated / uc_domains /
production via bronze-pipeline / UC native via _uc_object_map), cache it
locally, and write `_discovery/upstream_wikis/_index.json` summarising every
routing decision.

The upstream list is derived from:
  1. Phase 2 cached source code (regex over `FROM` / `JOIN` clauses).
  2. `knowledge/skills/_kpi_views_index.json` `refs[]` (if the object is listed).
  3. `_discovery/column_lineage/{Object}.json` `source_table_full_name` set.

Auth: pure file lookups + sqlglot, no Databricks API.

Usage:
  python tools/uc_pipelines/cache_upstream_wikis.py --schema etoro_kpi_prep
  python tools/uc_pipelines/cache_upstream_wikis.py --schema de_output --objects de_output_etoro_kpi_fact_customeraction_w_metrics
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"
SYNAPSE_WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"
UC_DOMAIN_ROOT = REPO / "knowledge" / "uc_domains"
GENERIC_PIPELINE_PATH = SYNAPSE_WIKI_ROOT / "_generic_pipeline_mapping.json"
UPSTREAM_ROUTING_PATH = SYNAPSE_WIKI_ROOT / "_upstream_wiki_routing.json"
UC_OBJECT_MAP_PATH = REPO / "knowledge" / "skills" / "_uc_object_map.json"
KPI_VIEWS_INDEX_PATH = REPO / "knowledge" / "skills" / "_kpi_views_index.json"
GLOBAL_WIKI_INDEX_PATH = OBJ_OUT_ROOT / "_upstream_wiki_index.json"

# Casing map for known Synapse schemas (UC snake_case → Synapse PascalCase folder).
SYNAPSE_SCHEMA_CASE = {
    "dwh_dbo": "DWH_dbo",
    "bi_db_dbo": "BI_DB_dbo",
    "dealing_dbo": "Dealing_dbo",
    "emoney_dbo": "eMoney_dbo",
    "exw_dbo": "EXW_dbo",
    "exw_wallet": "EXW_Wallet",
    "emoney_tribe": "eMoney_Tribe",
}

# Acquired-company domains routed via uc_domains/
UC_DOMAIN_SCHEMAS = {"spaceship", "moneyfarm"}

# This pack's schemas — populated dynamically below (anything that exists under
# UC_generated/).
def _uc_generated_schemas() -> set[str]:
    if not OBJ_OUT_ROOT.exists():
        return set()
    return {p.name for p in OBJ_OUT_ROOT.iterdir() if p.is_dir() and not p.name.startswith("_")}


# ---------- upstream extraction ----------

_FROM_JOIN_RE = re.compile(
    r"\b(?:FROM|JOIN)\s+([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+){1,2})",
    re.IGNORECASE,
)

# Identifiers we never want to treat as upstream tables.
_NOISE_REFS = {
    "information_schema",
    "system.access",
    "system.information_schema",
}


def extract_upstreams_from_sql(text: str, default_catalog: str = "main") -> list[str]:
    """Regex-extract upstream FQN-ish refs from a SQL string.

    Returns a deduplicated list of `main.{schema}.{table}` strings (best-effort
    normalisation; the routing step tolerates mismatches).
    """
    seen: list[str] = []
    for m in _FROM_JOIN_RE.finditer(text):
        ref = m.group(1)
        low = ref.lower()
        if any(n in low for n in _NOISE_REFS):
            continue
        parts = ref.split(".")
        if len(parts) == 2:
            fq = f"{default_catalog}.{parts[0]}.{parts[1]}"
        elif len(parts) == 3:
            fq = f"{parts[0]}.{parts[1]}.{parts[2]}"
        else:
            continue
        fq = fq.lower()
        if fq not in seen:
            seen.append(fq)
    return seen


def extract_upstreams_from_python(text: str) -> list[str]:
    """Find `spark.read.table(...)`, `spark.table(...)`, and `spark.sql("... FROM ...")` refs.

    Best-effort regex — Phase 4's sqlglot parse is the authoritative reading.
    """
    refs: list[str] = []

    # spark.{read.,}table("a.b.c")
    for m in re.finditer(r"spark\.(?:read\.)?table\s*\(\s*['\"]([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+){1,2})['\"]", text):
        refs.append(m.group(1).lower())

    # dlt.read("name") / dlt.read_stream("name") / dlt.readStream
    for m in re.finditer(r"dlt\.(?:read|read_stream|readStream)\s*\(\s*['\"]([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)?)['\"]", text):
        refs.append(m.group(1).lower())

    # spark.sql("... FROM x.y.z ...") — pull the SQL string and feed to the SQL extractor
    for m in re.finditer(
        r"spark\.sql\s*\(\s*(?:f?['\"]{3}|f?['\"])(.*?)(?:['\"]{3}|['\"])\s*\)",
        text, flags=re.DOTALL,
    ):
        refs.extend(extract_upstreams_from_sql(m.group(1)))

    # Normalise: if a ref only has one or two parts, assume catalog=main and the
    # schema is whatever appears as the leading segment.
    norm: list[str] = []
    for r in refs:
        parts = r.split(".")
        if len(parts) == 3:
            fq = r
        elif len(parts) == 2:
            fq = f"main.{r}"
        else:
            # bare name — skip (likely a DLT-local table alias)
            continue
        if fq not in norm:
            norm.append(fq)
    return norm


def upstreams_from_source_file(path: Path) -> list[str]:
    txt = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix.lower() == ".sql":
        return extract_upstreams_from_sql(txt)
    return extract_upstreams_from_sql(txt) + extract_upstreams_from_python(txt)


def upstreams_from_column_lineage(path: Path) -> list[str]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []
    refs: list[str] = []
    for row in payload.get("rows", []):
        src = (row.get("source_table_full_name") or "").lower()
        if src and src not in refs:
            refs.append(src)
    return refs


def upstreams_from_kpi_index(target: str, kpi_index: list) -> list[str]:
    """Pull `refs[]` from `_kpi_views_index.json` for a `{schema}.{name}` ref."""
    if not kpi_index:
        return []
    parts = target.split(".")
    if len(parts) != 3:
        return []
    catalog, schema, name = parts
    for entry in kpi_index:
        if entry.get("schema") == schema and entry.get("name") == name:
            refs = entry.get("refs") or []
            return [r.lower() if r.count(".") == 2 else f"main.{r.lower()}"
                    for r in refs]
    return []


# ---------- routing ----------

def route_upstream(full_name: str, generic_pipeline: list[dict],
                   uc_object_map: dict, uc_pack_schemas: set[str],
                   global_index: dict | None = None) -> dict:
    """Decide the routing rule for `full_name` and return a result dict.

    Returns shape:
      {
        "full_name": "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction",
        "rule_matched": 1,
        "rule_name": "synapse_gold_mirror",
        "wiki_path": "knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md",
        "wiki_exists": true,
        ...
      }
    """
    fn = full_name.lower()
    parts = fn.split(".")
    if len(parts) != 3:
        return {"full_name": full_name, "rule_matched": 6, "rule_name": "no_wiki",
                "reason": f"unparseable upstream ref ({len(parts)} parts)"}

    catalog, schema, name = parts

    # Rule 0 — global wiki index (fast O(1) hit, built once per run by
    # tools/uc_pipelines/build_upstream_wiki_index.py).
    if global_index is not None:
        hit = global_index.get(fn)
        if hit and hit.get("wiki_path"):
            kind = hit.get("wiki_kind") or "global_index"
            rule_num = {"synapse_mirror": 1, "uc_generated": 2,
                        "uc_domain": 3, "bronze_tier1": 1}.get(kind, 5)
            rule_name = {"synapse_mirror": "synapse_gold_mirror",
                         "uc_generated": "uc_generated_sibling",
                         "uc_domain": "uc_domain",
                         "bronze_tier1": "bronze_tier1_inheritance"}.get(kind, "uc_native_via_map")
            return {
                "full_name": full_name,
                "rule_matched": rule_num,
                "rule_name": rule_name,
                "wiki_path": hit["wiki_path"],
                "wiki_exists": True,
                "via_global_index": True,
            }

    # Rule 1 — synapse gold mirror
    if name.startswith("gold_sql_dp_prod_we_"):
        return _route_synapse_mirror(full_name, schema, name)

    # Rule 2 — UC_generated sibling
    if schema in uc_pack_schemas:
        return _route_uc_generated(full_name, schema, name)

    # Rule 3 — acquired-domain
    if schema in UC_DOMAIN_SCHEMAS:
        return _route_uc_domain(full_name, schema, name)

    # Rule 4 — bronze pure-ingest
    if name.startswith("bronze_"):
        r = _route_bronze(full_name, schema, name, generic_pipeline)
        if r:
            return r

    # Rule 5 — UC native via _uc_object_map
    mapped = uc_object_map.get(full_name) or uc_object_map.get(f"main.{schema}.{name}")
    if mapped:
        return {
            "full_name": full_name,
            "rule_matched": 5,
            "rule_name": "uc_native_via_map",
            "uc_target": mapped.get("uc_target"),
            "wiki_path": None,
            "wiki_exists": False,
            "notes": "matched in _uc_object_map.json but no wiki path is encoded there",
        }

    return {"full_name": full_name, "rule_matched": 6, "rule_name": "no_wiki",
            "reason": "no rule matched"}


def _route_synapse_mirror(full_name: str, schema: str, name: str) -> dict:
    """Strip `gold_sql_dp_prod_we_` and identify Synapse `{Schema}` + `{Table}`."""
    rest = name[len("gold_sql_dp_prod_we_"):]
    # rest is of form `{synapse_schema_snake}_{table_snake}`. We don't know
    # where the boundary is — try known synapse schemas longest-first.
    synapse_schema: str | None = None
    table_snake: str | None = None
    for synapse_snake in sorted(SYNAPSE_SCHEMA_CASE.keys(), key=len, reverse=True):
        if rest.startswith(synapse_snake + "_"):
            synapse_schema = SYNAPSE_SCHEMA_CASE[synapse_snake]
            table_snake = rest[len(synapse_snake) + 1:]
            break
    if not synapse_schema:
        return {"full_name": full_name, "rule_matched": 1,
                "rule_name": "synapse_gold_mirror",
                "wiki_path": None, "wiki_exists": False,
                "reason": f"couldn't split synapse schema from rest={rest!r}"}

    # Find the matching Tables/Views/Functions wiki by case-insensitive match
    schema_dir = SYNAPSE_WIKI_ROOT / synapse_schema
    wiki_path = None
    if schema_dir.is_dir():
        # Strip `_masked` suffix when looking up the wiki (PII split)
        base = table_snake[:-len("_masked")] if table_snake.endswith("_masked") else table_snake
        # Also strip "v_" prefix for view-proxy lookups, since some lookups
        # need to fall through to the underlying TABLE wiki.
        candidates_snake = [base]
        if base.startswith("v_"):
            candidates_snake.append(base[2:])
        for folder in ("Tables", "Views", "Functions"):
            d = schema_dir / folder
            if not d.is_dir():
                continue
            existing = {p.stem.lower(): p for p in d.glob("*.md")
                        if not (p.name.endswith(".lineage.md")
                                or p.name.endswith(".review-needed.md")
                                or p.name.endswith(".alter.sql"))}
            for cand in candidates_snake:
                hit = existing.get(cand)
                if hit:
                    wiki_path = hit
                    break
            if wiki_path:
                break

    return {
        "full_name": full_name,
        "rule_matched": 1,
        "rule_name": "synapse_gold_mirror",
        "synapse_schema": synapse_schema,
        "synapse_table_snake": table_snake,
        "wiki_path": str(wiki_path.relative_to(REPO)) if wiki_path else None,
        "wiki_exists": wiki_path is not None,
    }


def _route_uc_generated(full_name: str, schema: str, name: str) -> dict:
    schema_dir = OBJ_OUT_ROOT / schema
    wiki_path = None
    if schema_dir.is_dir():
        for folder in ("Views", "Tables"):
            cand = schema_dir / folder / f"{name}.md"
            if cand.exists():
                wiki_path = cand
                break
    return {
        "full_name": full_name,
        "rule_matched": 2,
        "rule_name": "uc_generated_sibling",
        "wiki_path": str(wiki_path.relative_to(REPO)) if wiki_path else f"knowledge/UC_generated/{schema}/<Tables|Views>/{name}.md",
        "wiki_exists": wiki_path is not None,
        "blocked_on_upstream": wiki_path is None,
    }


def _route_uc_domain(full_name: str, schema: str, name: str) -> dict:
    # Acquired-domain schemas are themselves named after the domain, OR they
    # are referenced from a domain folder. For now we search both possibilities.
    wiki_path = None
    for domain in UC_DOMAIN_SCHEMAS:
        schema_dir = UC_DOMAIN_ROOT / domain / "schemas" / schema
        if not schema_dir.is_dir():
            continue
        for folder in ("Views", "Tables"):
            cand = schema_dir / folder / f"{name}.md"
            if cand.exists():
                wiki_path = cand
                break
        if wiki_path:
            break
    return {
        "full_name": full_name,
        "rule_matched": 3,
        "rule_name": "uc_domain",
        "wiki_path": str(wiki_path.relative_to(REPO)) if wiki_path else None,
        "wiki_exists": wiki_path is not None,
    }


def _route_bronze(full_name: str, schema: str, name: str,
                  generic_pipeline: list[dict]) -> dict | None:
    # generic_pipeline rows have `uc_table` like `{business_group}.bronze_{db}_{schema}_{table}`.
    target_uc = f"{schema}.{name}"
    match = None
    for row in generic_pipeline:
        if (row.get("uc_table") or "").lower() == target_uc:
            match = row
            break
    if not match:
        return None

    db = match.get("database_name") or ""
    s = match.get("schema_name") or ""
    t = match.get("table_name") or ""

    # Use _upstream_wiki_routing.json to resolve the wiki path.
    try:
        routing = json.loads(UPSTREAM_ROUTING_PATH.read_text(encoding="utf-8"))
    except Exception:
        routing = {"upstream_databases": {}}

    db_entry = routing.get("upstream_databases", {}).get(db)
    wiki_md: Path | None = None
    if db_entry:
        repo_path = Path(db_entry["repo_path"])
        wiki_root = db_entry["wiki_path"]
        for folder in ("Tables", "Views", "Functions"):
            cand = repo_path / wiki_root / s / folder / f"{s}.{t}.md"
            if cand.exists():
                wiki_md = cand
                break

    return {
        "full_name": full_name,
        "rule_matched": 4,
        "rule_name": "bronze_pure_ingest",
        "generic_pipeline_row": {
            "database_name": db, "schema_name": s, "table_name": t,
            "uc_table": match.get("uc_table"),
        },
        "wiki_path": str(wiki_md.relative_to(REPO)) if wiki_md and wiki_md.is_relative_to(REPO) else (
            str(wiki_md) if wiki_md else None
        ),
        "wiki_exists": wiki_md is not None,
    }


# ---------- file I/O ----------

def cache_wiki(wiki_path_abs: Path, dest: Path) -> bool:
    if not wiki_path_abs.exists():
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(wiki_path_abs, dest)
    return True


def write_no_wiki_placeholder(dest: Path, full_name: str, reason: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    ts = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    body = (f"# Upstream wiki NOT found — {full_name}\n\n"
            f"Reason: {reason}\n\n"
            f"Cached at: {ts}\n\n"
            f"Phase 5 will treat columns sourced from this upstream as Tier 2 "
            f"(from cached source code) or Tier 4 (sample-inferred).\n")
    dest.write_text(body, encoding="utf-8")


# ---------- main ----------

def collect_upstreams_for_object(schema_root: Path, obj_name: str,
                                  kpi_index: list) -> list[str]:
    """Union of upstreams from cached source code + column_lineage + kpi index."""
    refs: list[str] = []

    src_dir = schema_root / "_discovery" / "source_code"
    for ext in ("sql", "py", "scala", "r"):
        p = src_dir / f"{obj_name}.{ext}"
        if p.exists():
            for r in upstreams_from_source_file(p):
                if r not in refs:
                    refs.append(r)
            break

    cl = schema_root / "_discovery" / "column_lineage" / f"{obj_name}.json"
    if cl.exists():
        for r in upstreams_from_column_lineage(cl):
            if r not in refs:
                refs.append(r)

    # KPI index by `main.{schema}.{name}`
    full = f"main.{schema_root.name}.{obj_name}".lower()
    for r in upstreams_from_kpi_index(full, kpi_index):
        if r not in refs:
            refs.append(r)

    return refs


def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline upstream-wiki bridge (Phase 3)")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--objects", nargs="+", default=None,
                    help="Optional subset; default all in-scope from _schema_card.md")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--write-cache", action="store_true", default=True,
                    help="(default ON) copy upstream wiki BODIES into _discovery/upstream_wikis/")
    ap.add_argument("--no-write-cache", dest="write_cache", action="store_false",
                    help="Routing-only mode: only write _index.json, skip body copies")
    ap.add_argument("--use-global-index", action="store_true", default=True,
                    help="(default ON) consult _upstream_wiki_index.json before per-rule lookups")
    ap.add_argument("--no-global-index", dest="use_global_index", action="store_false")
    ap.add_argument("--force", action="store_true",
                    help="Re-route all upstreams even if cached")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    if not schema_root.exists():
        print(f"[upstream-bridge] schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    card = schema_root / "_schema_card.md"
    if not card.exists():
        print(f"[upstream-bridge] {card} missing — run discover_schema.py first", file=sys.stderr)
        return 2

    # Load registries
    try:
        gp = json.loads(GENERIC_PIPELINE_PATH.read_text(encoding="utf-8"))
        generic_pipeline = gp.get("mappings", [])
    except Exception as e:
        print(f"[upstream-bridge] WARN: generic_pipeline_mapping load failed: {e}", file=sys.stderr)
        generic_pipeline = []
    try:
        uc_om = json.loads(UC_OBJECT_MAP_PATH.read_text(encoding="utf-8"))
        uc_object_map = uc_om.get("objects", {})
    except Exception as e:
        print(f"[upstream-bridge] WARN: _uc_object_map.json load failed: {e}", file=sys.stderr)
        uc_object_map = {}
    try:
        kpi_index = json.loads(KPI_VIEWS_INDEX_PATH.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[upstream-bridge] WARN: _kpi_views_index.json load failed: {e}", file=sys.stderr)
        kpi_index = []

    uc_pack_schemas = _uc_generated_schemas()

    global_index_lookup: dict | None = None
    if args.use_global_index:
        try:
            gi = json.loads(GLOBAL_WIKI_INDEX_PATH.read_text(encoding="utf-8"))
            global_index_lookup = gi.get("wikis", {})
            print(f"[upstream-bridge] global index: {len(global_index_lookup)} wikis available",
                  file=sys.stderr)
        except FileNotFoundError:
            print(f"[upstream-bridge] global index not found at {GLOBAL_WIKI_INDEX_PATH} "
                  f"— run build_upstream_wiki_index.py first for faster routing",
                  file=sys.stderr)
        except Exception as e:
            print(f"[upstream-bridge] WARN: global index load failed: {e}", file=sys.stderr)

    # Read schema card frontmatter
    try:
        import yaml  # type: ignore
        m = re.match(r"^---\n(.+?)\n---\n", card.read_text(encoding="utf-8"), re.DOTALL)
        card_data = yaml.safe_load(m.group(1))
    except Exception as e:
        print(f"[upstream-bridge] couldn't parse schema card: {e}", file=sys.stderr)
        return 2

    in_scope = [o for o in (card_data.get("objects") or []) if o.get("in_scope")]
    if args.objects:
        keep = set(args.objects)
        in_scope = [o for o in in_scope if o["name"] in keep]

    print(f"[upstream-bridge] {args.catalog}.{args.schema} → {len(in_scope)} in-scope objects",
          file=sys.stderr, flush=True)

    # For each object, collect upstreams and route each one
    all_routed: dict[str, dict] = {}
    per_object_index: dict[str, list[str]] = {}

    for i, obj in enumerate(in_scope, 1):
        name = obj["name"]
        refs = collect_upstreams_for_object(schema_root, name, kpi_index)
        print(f"  [{i}/{len(in_scope)}] {name} → {len(refs)} upstream refs", file=sys.stderr)
        per_object_index[name] = refs
        for ref in refs:
            if ref in all_routed:
                continue
            decision = route_upstream(ref, generic_pipeline, uc_object_map, uc_pack_schemas,
                                       global_index=global_index_lookup)
            all_routed[ref] = decision

    # Cache hits
    cache_root = schema_root / "_discovery" / "upstream_wikis"
    cache_root.mkdir(parents=True, exist_ok=True)
    cached_files: list[str] = []
    placeholder_files: list[str] = []

    for ref, decision in sorted(all_routed.items()):
        if decision.get("wiki_exists") and decision.get("wiki_path"):
            if args.write_cache:
                src = REPO / decision["wiki_path"]
                dest = cache_root / f"{ref}.md"
                if cache_wiki(src, dest):
                    decision["cached_at"] = str(dest.relative_to(REPO))
                    cached_files.append(decision["cached_at"])
        else:
            if args.write_cache:
                dest = cache_root / f"_NO_WIKI__{ref}.md"
                reason = decision.get("reason") or decision.get("rule_name") or "no rule matched"
                write_no_wiki_placeholder(dest, ref, reason)
                decision["cached_at"] = str(dest.relative_to(REPO))
                placeholder_files.append(decision["cached_at"])

    stats = {
        "total_upstreams": len(all_routed),
        "rule1_synapse_mirror": sum(1 for d in all_routed.values() if d.get("rule_matched") == 1),
        "rule2_uc_generated": sum(1 for d in all_routed.values() if d.get("rule_matched") == 2),
        "rule3_uc_domain": sum(1 for d in all_routed.values() if d.get("rule_matched") == 3),
        "rule4_bronze_prod": sum(1 for d in all_routed.values() if d.get("rule_matched") == 4),
        "rule5_uc_native_map": sum(1 for d in all_routed.values() if d.get("rule_matched") == 5),
        "rule6_no_wiki": sum(1 for d in all_routed.values() if d.get("rule_matched") == 6),
        "wikis_cached": len(cached_files),
        "no_wiki_placeholders": len(placeholder_files),
        "blocked_on_upstream": sum(1 for d in all_routed.values() if d.get("blocked_on_upstream")),
    }

    index = {
        "schema": args.schema,
        "catalog": args.catalog,
        "framework": "uc-pipeline-doc",
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "per_object_upstreams": per_object_index,
        "upstreams": [all_routed[k] for k in sorted(all_routed.keys())],
        "stats": stats,
    }
    idx_path = cache_root / "_index.json"
    idx_path.write_text(json.dumps(index, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[upstream-bridge] wrote {idx_path}", file=sys.stderr)
    print(f"[upstream-bridge] stats={stats}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
