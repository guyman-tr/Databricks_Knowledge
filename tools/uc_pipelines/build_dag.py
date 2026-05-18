#!/usr/bin/env python3
"""
Phase -1 — One-Shot Lineage DAG Builder (UC-Pipeline pack).

Issues exactly ONE `system.access.column_lineage` query and ONE
`system.access.table_lineage` query (90-day lookback, filtered to the pilot
schemas) plus at most TWO `system.information_schema` queries for table_type +
column_count. This is the UC-query budget hard ceiling per FR-005 / SC-005.

Output: `knowledge/UC_generated/_dag.json` matching `contracts/dag.schema.json`.

The DAG is then consumed by:
  - `run_pipeline.py` for topological scheduling (bottom-up: layer 0 first).
  - `cache_upstream_wikis.py` for per-schema upstream wiki bridging.
  - `generate_wiki.py` for inheritance-chain resolution.
  - `validate_pipeline_wiki.py` for Assertion 13 (no-inference enforcement).
  - `write_audit_summary.py` for per-run reconciliation.

Usage:
  python tools/uc_pipelines/build_dag.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi
  python tools/uc_pipelines/build_dag.py --schemas etoro_kpi_prep --catalog main --output knowledge/UC_generated/_dag.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"
GLOBAL_WIKI_INDEX_PATH = OBJ_OUT_ROOT / "_upstream_wiki_index.json"
DEFAULT_OUT_PATH = OBJ_OUT_ROOT / "_dag.json"
DEFAULT_PILOT_SCHEMAS = ["de_output", "bi_output", "bi_dealing", "etoro_kpi_prep", "etoro_kpi"]


def _norm(fqn: str | None) -> str | None:
    if not fqn:
        return None
    return fqn.lower().strip()


def _build_column_lineage_query(catalog: str, pilot_schemas: list[str], lookback_days: int) -> str:
    schemas_sql = ", ".join(f"'{s}'" for s in pilot_schemas)
    return f"""
        SELECT
            source_table_catalog,
            source_table_schema,
            source_table_name,
            source_table_full_name,
            source_column_name,
            target_table_catalog,
            target_table_schema,
            target_table_name,
            target_table_full_name,
            target_column_name,
            COUNT(*) AS event_count
        FROM system.access.column_lineage
        WHERE event_date >= current_date() - INTERVAL {lookback_days} DAYS
          AND target_table_catalog = '{catalog}'
          AND (
              target_table_schema IN ({schemas_sql})
              OR source_table_schema IN ({schemas_sql})
          )
          AND target_table_full_name IS NOT NULL
        GROUP BY ALL
    """


def _build_table_lineage_query(catalog: str, pilot_schemas: list[str], lookback_days: int) -> str:
    schemas_sql = ", ".join(f"'{s}'" for s in pilot_schemas)
    return f"""
        SELECT
            source_table_catalog,
            source_table_schema,
            source_table_name,
            source_table_full_name,
            target_table_catalog,
            target_table_schema,
            target_table_name,
            target_table_full_name,
            COUNT(*) AS event_count
        FROM system.access.table_lineage
        WHERE event_date >= current_date() - INTERVAL {lookback_days} DAYS
          AND target_table_catalog = '{catalog}'
          AND (
              target_table_schema IN ({schemas_sql})
              OR source_table_schema IN ({schemas_sql})
          )
          AND target_table_full_name IS NOT NULL
        GROUP BY ALL
    """


def _build_information_schema_query(catalog: str, pilot_schemas: list[str]) -> str:
    schemas_sql = ", ".join(f"'{s}'" for s in pilot_schemas)
    return f"""
        SELECT
            table_catalog,
            table_schema,
            table_name,
            CONCAT(table_catalog, '.', table_schema, '.', table_name) AS full_name,
            table_type,
            (
                SELECT COUNT(*)
                FROM {catalog}.information_schema.columns AS c
                WHERE c.table_catalog = t.table_catalog
                  AND c.table_schema = t.table_schema
                  AND c.table_name = t.table_name
            ) AS column_count
        FROM {catalog}.information_schema.tables AS t
        WHERE table_catalog = '{catalog}'
          AND table_schema IN ({schemas_sql})
    """


def run_uc_queries(catalog: str, pilot_schemas: list[str],
                   lookback_days: int) -> tuple[list[dict], list[dict], list[dict], dict]:
    """Issue the three queries with hard budget tracking. Returns
    (column_lineage_rows, table_lineage_rows, info_schema_rows, budget)."""
    from uc_pipelines._conn import connect

    budget = {
        "column_lineage_queries": 0,
        "table_lineage_queries": 0,
        "information_schema_queries": 0,
    }
    col_rows: list[dict] = []
    tab_rows: list[dict] = []
    inf_rows: list[dict] = []

    conn = connect()
    try:
        with conn.cursor() as cur:
            print(f"[build-dag] issuing column_lineage query (90-day lookback)...",
                  file=sys.stderr, flush=True)
            cur.execute(_build_column_lineage_query(catalog, pilot_schemas, lookback_days))
            budget["column_lineage_queries"] += 1
            cols = [d[0] for d in cur.description]
            col_rows = [dict(zip(cols, r)) for r in cur.fetchall()]
            print(f"[build-dag]   → {len(col_rows)} column-lineage rows",
                  file=sys.stderr, flush=True)

            print(f"[build-dag] issuing table_lineage query (90-day lookback)...",
                  file=sys.stderr, flush=True)
            cur.execute(_build_table_lineage_query(catalog, pilot_schemas, lookback_days))
            budget["table_lineage_queries"] += 1
            cols = [d[0] for d in cur.description]
            tab_rows = [dict(zip(cols, r)) for r in cur.fetchall()]
            print(f"[build-dag]   → {len(tab_rows)} table-lineage rows",
                  file=sys.stderr, flush=True)

            print(f"[build-dag] issuing information_schema query for in-scope nodes...",
                  file=sys.stderr, flush=True)
            cur.execute(_build_information_schema_query(catalog, pilot_schemas))
            budget["information_schema_queries"] += 1
            cols = [d[0] for d in cur.description]
            inf_rows = [dict(zip(cols, r)) for r in cur.fetchall()]
            print(f"[build-dag]   → {len(inf_rows)} in-scope information_schema rows",
                  file=sys.stderr, flush=True)
    finally:
        try:
            conn.close()
        except Exception:
            pass

    return col_rows, tab_rows, inf_rows, budget


def _classify_wiki_status(
    full_name: str,
    catalog: str,
    schema: str,
    in_pilot_scope: bool,
    has_pack_wiki: bool,
    global_wiki_hit: dict | None,
) -> tuple[str, int | None, str | None]:
    """Returns (wiki_status, routing_rule, cached_wiki_path) per dag.schema.json."""
    if has_pack_wiki:
        pack_md = OBJ_OUT_ROOT / schema / "Tables" / f"{full_name.split('.')[-1]}.md"
        if not pack_md.exists():
            pack_md = OBJ_OUT_ROOT / schema / "Views" / f"{full_name.split('.')[-1]}.md"
        return ("documented_in_pack", 2,
                str(pack_md.relative_to(REPO)).replace("\\", "/") if pack_md.exists() else None)

    if global_wiki_hit:
        kind = global_wiki_hit.get("wiki_kind")
        rule = {"synapse_mirror": 1, "uc_generated": 2, "uc_domain": 3,
                "bronze_tier1": 1}.get(kind, 5)
        if kind == "uc_generated" and in_pilot_scope:
            return ("documented_in_pack", rule, global_wiki_hit.get("wiki_path"))
        # Bronze with a Tier 1 wiki in scope of this pipeline run is treated as
        # a target to author (inheriting from Tier 1), not as already-documented
        # externally. The schema card's classify_writer already flips it to
        # in_scope=True with kind=BRONZE_TIER1_INHERITANCE in that case.
        if kind == "bronze_tier1" and in_pilot_scope:
            return ("in_scope_not_yet_authored", rule, global_wiki_hit.get("wiki_path"))
        return ("documented_external", rule, global_wiki_hit.get("wiki_path"))

    if in_pilot_scope:
        return ("in_scope_not_yet_authored", None, None)

    return ("out_of_scope", None, None)


def build_dag_structure(
    column_lineage_rows: list[dict],
    table_lineage_rows: list[dict],
    info_schema_rows: list[dict],
    pilot_schemas: list[str],
    catalog: str,
    global_wiki_index: dict,
) -> tuple[list[dict], list[dict]]:
    """Builds DAG nodes + edges from the three query result sets."""

    pilot_set = set(s.lower() for s in pilot_schemas)
    info_by_fqn: dict[str, dict] = {}
    for r in info_schema_rows:
        fn = _norm(r.get("full_name") or "") or ""
        if fn:
            info_by_fqn[fn] = r

    all_fqns: set[str] = set()
    for r in column_lineage_rows:
        s = _norm(r.get("source_table_full_name"))
        t = _norm(r.get("target_table_full_name"))
        if s:
            all_fqns.add(s)
        if t:
            all_fqns.add(t)
    for r in table_lineage_rows:
        s = _norm(r.get("source_table_full_name"))
        t = _norm(r.get("target_table_full_name"))
        if s:
            all_fqns.add(s)
        if t:
            all_fqns.add(t)
    for fn in info_by_fqn:
        all_fqns.add(fn)

    pack_wiki_fqns: set[str] = set()
    if OBJ_OUT_ROOT.is_dir():
        for schema_dir in OBJ_OUT_ROOT.iterdir():
            if not schema_dir.is_dir() or schema_dir.name.startswith("_"):
                continue
            for folder in ("Tables", "Views"):
                d = schema_dir / folder
                if d.is_dir():
                    for md in d.glob("*.md"):
                        if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                            continue
                        pack_wiki_fqns.add(f"main.{schema_dir.name}.{md.stem}".lower())

    source_code_cache_fqns: set[str] = set()
    if OBJ_OUT_ROOT.is_dir():
        for schema_dir in OBJ_OUT_ROOT.iterdir():
            if not schema_dir.is_dir() or schema_dir.name.startswith("_"):
                continue
            src_dir = schema_dir / "_discovery" / "source_code"
            if src_dir.is_dir():
                for f in src_dir.iterdir():
                    if f.is_file() and f.suffix in (".sql", ".py", ".scala", ".r"):
                        source_code_cache_fqns.add(f"main.{schema_dir.name}.{f.stem}".lower())

    nodes_in_progress: dict[str, dict] = {}
    for fqn in sorted(all_fqns):
        parts = fqn.split(".")
        if len(parts) != 3:
            continue
        cat, sch, name = parts
        in_pilot = (sch in pilot_set) and (cat == catalog.lower())
        info = info_by_fqn.get(fqn) or {}
        table_type = info.get("table_type") or ("VIEW" if name.startswith("v_") else "MANAGED")

        global_hit = global_wiki_index.get(fqn)
        has_pack = fqn in pack_wiki_fqns

        wiki_status, routing_rule, cached = _classify_wiki_status(
            fqn, cat, sch, in_pilot, has_pack, global_hit,
        )

        if not in_pilot and not global_hit and not has_pack:
            if not any(_norm(r.get("source_table_full_name")) == fqn
                       for r in column_lineage_rows + table_lineage_rows):
                wiki_status = "terminal_no_wiki"

        nodes_in_progress[fqn] = {
            "full_name": fqn,
            "catalog": cat,
            "schema": sch,
            "table_type": table_type,
            "wiki_status": wiki_status,
            "routing_rule": routing_rule,
            "cached_wiki_path": cached,
            "in_pilot_scope": in_pilot,
            "topological_layer": 0,
            "source_code_available": fqn in source_code_cache_fqns,
            "column_count": int(info.get("column_count") or 0),
        }

    edges: list[dict] = []
    passthrough_seen: dict[tuple[str, str, str, str], bool] = defaultdict(lambda: True)
    edge_counts: dict[tuple[str, str, str, str], int] = defaultdict(int)

    for r in column_lineage_rows:
        s = _norm(r.get("source_table_full_name"))
        t = _norm(r.get("target_table_full_name"))
        sc = r.get("source_column_name") or ""
        tc = r.get("target_column_name") or ""
        ev = int(r.get("event_count") or 1)
        if not (s and t and sc and tc):
            continue
        key = (s, t, sc, tc)
        edge_counts[key] += ev
        if sc.lower() != tc.lower():
            passthrough_seen[key] = False

    for (s, t, sc, tc), cnt in edge_counts.items():
        edges.append({
            "from_node": s,
            "to_node": t,
            "from_column": sc,
            "to_column": tc,
            "event_count_90d": cnt,
            "is_passthrough_only": passthrough_seen[(s, t, sc, tc)],
        })

    table_edge_keys: dict[tuple[str, str], int] = defaultdict(int)
    for r in table_lineage_rows:
        s = _norm(r.get("source_table_full_name"))
        t = _norm(r.get("target_table_full_name"))
        ev = int(r.get("event_count") or 1)
        if s and t:
            table_edge_keys[(s, t)] += ev

    col_edge_node_pairs = {(e["from_node"], e["to_node"]) for e in edges}
    for (s, t), cnt in table_edge_keys.items():
        if (s, t) in col_edge_node_pairs:
            continue
        edges.append({
            "from_node": s,
            "to_node": t,
            "from_column": "(table-lineage-only)",
            "to_column": "(table-lineage-only)",
            "event_count_90d": cnt,
            "is_passthrough_only": False,
        })

    indeg: dict[str, int] = {fqn: 0 for fqn in nodes_in_progress}
    succ: dict[str, list[str]] = defaultdict(list)
    pair_seen: set[tuple[str, str]] = set()
    for e in edges:
        f, t = e["from_node"], e["to_node"]
        if (f, t) in pair_seen:
            continue
        if f == t:
            continue
        if f not in nodes_in_progress or t not in nodes_in_progress:
            continue
        pair_seen.add((f, t))
        succ[f].append(t)
        indeg[t] += 1

    layer: dict[str, int] = {fqn: 0 for fqn in nodes_in_progress}
    q = deque([fqn for fqn, d in indeg.items() if d == 0])
    visited: set[str] = set()
    while q:
        node = q.popleft()
        if node in visited:
            continue
        visited.add(node)
        for nxt in succ.get(node, []):
            new_layer = layer[node] + 1
            if new_layer > layer[nxt]:
                layer[nxt] = new_layer
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)

    cycle_fqns = [fqn for fqn in nodes_in_progress if fqn not in visited]
    if cycle_fqns:
        print(f"[build-dag] WARN: {len(cycle_fqns)} nodes left unvisited "
              f"(possible cycle): {cycle_fqns[:5]}", file=sys.stderr, flush=True)

    for fqn, n in nodes_in_progress.items():
        n["topological_layer"] = layer.get(fqn, 0)

    nodes_out = sorted(nodes_in_progress.values(),
                       key=lambda n: (n["topological_layer"], n["full_name"]))
    return nodes_out, edges


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase -1 — One-shot DAG builder (UC-Pipeline pack)")
    ap.add_argument("--schemas", default=",".join(DEFAULT_PILOT_SCHEMAS),
                    help="Comma-separated pilot schemas to scope the DAG to")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--lookback-days", type=int, default=90)
    ap.add_argument("--output", default=str(DEFAULT_OUT_PATH),
                    help="Output JSON path (default: knowledge/UC_generated/_dag.json)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Show what would be queried + return without hitting UC")
    args = ap.parse_args()

    pilot_schemas = [s.strip() for s in args.schemas.split(",") if s.strip()]
    if not pilot_schemas:
        print("ERROR: no pilot schemas specified", file=sys.stderr)
        return 4

    if args.dry_run:
        print("[build-dag] DRY-RUN — would issue 3 UC queries:")
        print("  1. column_lineage:", _build_column_lineage_query(
            args.catalog, pilot_schemas, args.lookback_days)[:200], "...")
        print("  2. table_lineage:", _build_table_lineage_query(
            args.catalog, pilot_schemas, args.lookback_days)[:200], "...")
        print("  3. information_schema:", _build_information_schema_query(
            args.catalog, pilot_schemas)[:200], "...")
        return 0

    global_wiki_index: dict = {}
    if GLOBAL_WIKI_INDEX_PATH.exists():
        try:
            gi = json.loads(GLOBAL_WIKI_INDEX_PATH.read_text(encoding="utf-8"))
            global_wiki_index = gi.get("wikis", {})
            print(f"[build-dag] global wiki index loaded: {len(global_wiki_index)} wikis",
                  file=sys.stderr, flush=True)
        except Exception as e:
            print(f"[build-dag] WARN: global index load failed: {e}", file=sys.stderr)
    else:
        print(f"[build-dag] WARN: {GLOBAL_WIKI_INDEX_PATH} not found — "
              f"run tools/uc_pipelines/build_upstream_wiki_index.py first for "
              f"accurate wiki_status classification", file=sys.stderr)

    try:
        col_rows, tab_rows, inf_rows, budget = run_uc_queries(
            args.catalog, pilot_schemas, args.lookback_days,
        )
    except Exception as e:
        print(f"[build-dag] ABORT — UC query failed: {e}", file=sys.stderr, flush=True)
        return 2

    nodes, edges = build_dag_structure(
        col_rows, tab_rows, inf_rows, pilot_schemas, args.catalog, global_wiki_index,
    )

    payload = {
        "built_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "uc_query_budget": budget,
        "pilot_schemas": pilot_schemas,
        "nodes": nodes,
        "edges": edges,
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")

    in_scope_nodes = sum(1 for n in nodes if n["in_pilot_scope"])
    out_scope_nodes = len(nodes) - in_scope_nodes
    max_layer = max((n["topological_layer"] for n in nodes), default=0)
    print(f"[build-dag] DONE: wrote {out_path.relative_to(REPO) if out_path.is_absolute() else out_path}")
    print(f"[build-dag]   nodes={len(nodes)} ({in_scope_nodes} in-scope, "
          f"{out_scope_nodes} out-of-scope), edges={len(edges)}, layers={max_layer + 1}")
    print(f"[build-dag]   budget={budget}")

    by_status: dict[str, int] = defaultdict(int)
    for n in nodes:
        by_status[n["wiki_status"]] += 1
    print(f"[build-dag]   wiki_status breakdown: {dict(by_status)}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
