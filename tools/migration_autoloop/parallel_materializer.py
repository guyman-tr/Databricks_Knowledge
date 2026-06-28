"""Parallel-schema materializer for the production-parallel DWH orchestration.

For each target in the ring, this module:
1. Ensures ``dwh_daily_process.migration_parallel`` schema exists.
2. SHALLOW CLONEs the target's gold table into ``migration_parallel`` — zero-copy,
   instantaneous even for 2.86B-row ``dim_position``.
3. Discovers all ``migration_tables.*`` source-table references in the proc call graph
   and SHALLOW CLONEs those that have a gold equivalent.
4. Rewrites the entire proc/UDF call graph (``migration_tables`` -> ``migration_parallel``)
   and CREATE OR REPLACEs them in the parallel schema.

The rewritten procs are always derived fresh from the POC procs — zero drift, POC untouched.
"""
from __future__ import annotations

import re
import time
from dataclasses import dataclass, field
from typing import Any

if __package__ in {None, ""}:
    import sys
    from pathlib import Path

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from databricks.sdk import WorkspaceClient

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

PARALLEL_SCHEMA = "dwh_daily_process.migration_parallel"
MIGRATION_SCHEMA = "dwh_daily_process.migration_tables"

# Gold catalog / schema candidates tried in order for the convention-based resolver
_GOLD_NAMESPACES = ["main.dwh", "main.compliance"]


# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

def ensure_schema(w: WorkspaceClient, wid: str) -> None:
    execute_sql(
        w,
        sql_text="CREATE SCHEMA IF NOT EXISTS dwh_daily_process.migration_parallel",
        warehouse_id=wid,
    )


# ---------------------------------------------------------------------------
# Routine catalog helpers
# ---------------------------------------------------------------------------

def _get_all_routine_names(w: WorkspaceClient, wid: str) -> dict[str, str]:
    """Return {lower(routine_name): routine_type} for everything in migration_tables."""
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_name, routine_type "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables'"
        ),
        warehouse_id=wid,
    )
    return {str(r[0]).lower(): str(r[1]) for r in rows}


def _get_routine_body(w: WorkspaceClient, wid: str, proc_name: str) -> tuple[str, str] | None:
    """Return (canonical_name, body) for ``proc_name`` in migration_tables.

    Uses case-insensitive lookup — Databricks stores names lowercase but the
    proc body may reference them in mixed case.
    Returns ``None`` when the routine does not exist.
    """
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_name, routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND LOWER(routine_name)=LOWER('{proc_name}')"
        ),
        warehouse_id=wid,
    )
    if not rows:
        return None
    return str(rows[0][0]), str(rows[0][1])


def _get_routine_signature(w: WorkspaceClient, wid: str, proc_name: str) -> tuple[str, str, list[tuple[str, str]]]:
    """Return (routine_type, return_type, [(param_name, data_type), ...]).

    Uses case-insensitive lookup.
    """
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_name, routine_type, data_type "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND LOWER(routine_name)=LOWER('{proc_name}')"
        ),
        warehouse_id=wid,
    )
    if not rows:
        return ("PROCEDURE", "", [])
    canonical_name = str(rows[0][0])
    routine_type = str(rows[0][1])
    return_type = str(rows[0][2]) if rows[0][2] else ""

    _, prows = execute_sql(
        w,
        sql_text=(
            "SELECT parameter_name, data_type "
            "FROM system.information_schema.parameters "
            "WHERE specific_catalog='dwh_daily_process' "
            "AND specific_schema='migration_tables' "
            f"AND LOWER(specific_name)=LOWER('{proc_name}') "
            "ORDER BY ordinal_position"
        ),
        warehouse_id=wid,
    )
    params = [(str(r[0]), str(r[1])) for r in prows if r[0] is not None]
    return (routine_type, return_type, params)


# ---------------------------------------------------------------------------
# Call-graph walker
# ---------------------------------------------------------------------------

def _find_refs_in_body(body: str, all_routines: dict[str, str]) -> tuple[set[str], set[str]]:
    """Return (routine_refs, table_refs) of migration_tables names found in ``body``.

    ``routine_refs`` — names that match a known routine.
    ``table_refs``   — everything else (source tables, target tables).
    """
    pattern = re.compile(
        r"(?:dwh_daily_process\.)?migration_tables\.([A-Za-z0-9_]+)",
        re.IGNORECASE,
    )
    routine_refs: set[str] = set()
    table_refs: set[str] = set()
    for m in pattern.finditer(body):
        name = m.group(1)
        if name.lower() in all_routines:
            routine_refs.add(name)
        else:
            table_refs.add(name)
    return routine_refs, table_refs


def walk_call_graph(
    w: WorkspaceClient, wid: str, root_proc: str
) -> list[str]:
    """BFS over proc/function call graph starting from ``root_proc``.

    Returns canonical (stored) routine names in breadth-first order.
    """
    all_routines = _get_all_routine_names(w, wid)
    visited: set[str] = set()
    queue: list[str] = [root_proc]
    order: list[str] = []

    while queue:
        name = queue.pop(0)
        if name.lower() in visited:
            continue
        visited.add(name.lower())
        result = _get_routine_body(w, wid, name)
        if result is not None:
            canonical_name, body = result
            order.append(canonical_name)
            routine_refs, _ = _find_refs_in_body(body, all_routines)
            for ref in sorted(routine_refs):
                if ref.lower() not in visited:
                    queue.append(ref)
        # If body is None the name will not be added to order;
        # it will be skipped as "body_not_found" during materialize_routines.

    return order


# ---------------------------------------------------------------------------
# Gold resolver
# ---------------------------------------------------------------------------

def resolve_gold_fqn(
    table_name: str,
    overrides: dict[str, str] | None = None,
) -> str | None:
    """Map a ``migration_tables`` table name to its gold FQN.

    1. Check ``overrides`` dict (keys are lower-case table names).
    2. Try ``main.dwh.gold_sql_dp_prod_we_dwh_dbo_{lower}``.
    3. Try ``main.compliance.gold_sql_dp_prod_we_dwh_dbo_{lower}``.
    Returns ``None`` when the table has no known gold equivalent.
    """
    low = table_name.lower()
    if overrides and low in overrides:
        return overrides[low]
    convention = f"gold_sql_dp_prod_we_dwh_dbo_{low}"
    for ns in _GOLD_NAMESPACES:
        return f"{ns}.{convention}"
    return None  # unreachable but makes linter happy


def _gold_table_exists(w: WorkspaceClient, wid: str, fqn: str) -> bool:
    try:
        parts = fqn.split(".")
        cat, sch, tbl = parts[0], parts[1], parts[2]
        _, rows = execute_sql(
            w,
            sql_text=(
                f"SELECT 1 FROM system.information_schema.tables "
                f"WHERE table_catalog='{cat}' AND table_schema='{sch}' AND table_name='{tbl}'"
            ),
            warehouse_id=wid,
        )
        return len(rows) > 0
    except Exception:
        return False


def resolve_verified_gold_fqn(
    w: WorkspaceClient,
    wid: str,
    table_name: str,
    overrides: dict[str, str] | None = None,
) -> str | None:
    """Like ``resolve_gold_fqn`` but verifies the table exists (tries both namespaces)."""
    low = table_name.lower()
    if overrides and low in overrides:
        return overrides[low]
    convention = f"gold_sql_dp_prod_we_dwh_dbo_{low}"
    for ns in _GOLD_NAMESPACES:
        fqn = f"{ns}.{convention}"
        if _gold_table_exists(w, wid, fqn):
            return fqn
    return None


# ---------------------------------------------------------------------------
# SHALLOW CLONE
# ---------------------------------------------------------------------------

def clone_table(
    w: WorkspaceClient,
    wid: str,
    *,
    gold_fqn: str,
    target_name: str,
    baseline_filter: str = "1=0",
    skip_if_populated: bool = False,
    pre_flip_ts: str | None = None,
) -> dict[str, Any]:
    """Clone ``gold_fqn`` -> ``migration_parallel.target_name``.

    Strategy (tried in order):
    1. SHALLOW CLONE — zero-copy metadata-only clone. Requires both source and
       target to be UC Managed tables.
    2. CTAS fallback — ``CREATE TABLE … AS SELECT * FROM gold WHERE {baseline_filter}``.
       Default filter ``1=0`` creates an empty schema-matching table (correct for
       full-refresh targets). For incremental targets, pass e.g.
       ``"etr_ymd < '2026-06-23'"`` to seed the baseline with historical rows.

    ``pre_flip_ts``: when provided (format ``'YYYY-MM-DD HH:MM:SS'``), the clone
    uses ``AS OF TIMESTAMP`` to pin the gold table to its pre-flip state (D-2).
    This is critical when Phase A runs after the gold flip (e.g. 07:30 UTC):
    without it the clone would include D-1 rows Synapse already wrote, causing
    proc increments to read as zero (rows already exist in the clone).
    Pass ``'{target_date+1} 01:00:00'`` — 01:00 UTC of the run day, before any
    gold flip (~03:32-04:49 UTC on normal days).
    Ignored when ``baseline_filter='1=0'`` (schema-only copies don't need time-travel).

    When ``skip_if_populated=True``, the clone is skipped entirely if the target
    table already exists in migration_parallel with at least one row.  This
    prevents overwriting data written by a prior ring (e.g. ``dim_country``
    populated by Ring 0 should not be wiped when Ring 2 materializes).

    Returns a result dict with strategy, status, and elapsed_ms.
    """
    full_target = f"{PARALLEL_SCHEMA}.{target_name}"
    started = time.time()

    if skip_if_populated:
        try:
            _, rows = execute_sql(
                w,
                sql_text=f"SELECT COUNT(*) AS c FROM {full_target}",
                warehouse_id=wid,
                poll_deadline_sec=60.0,
            )
            if rows and int(rows[0][0]) > 0:
                return {
                    "action": "skip_already_populated",
                    "target": full_target,
                    "row_count": int(rows[0][0]),
                    "elapsed_ms": int((time.time() - started) * 1000),
                    "ok": True,
                }
        except RuntimeError:
            pass  # Table doesn't exist yet — proceed with clone

    # Build time-travel clause when pre_flip_ts is set AND we're copying real data
    # (baseline_filter="1=0" means schema-only — time-travel irrelevant for empty tables).
    ts_clause = ""
    if pre_flip_ts and baseline_filter != "1=0":
        ts_clause = f" TIMESTAMP AS OF '{pre_flip_ts}'"

    # Try SHALLOW CLONE first (fastest, metadata-only)
    try:
        execute_sql(
            w,
            sql_text=f"CREATE OR REPLACE TABLE {full_target} SHALLOW CLONE {gold_fqn}{ts_clause}",
            warehouse_id=wid,
            poll_deadline_sec=300.0,
        )
        return {
            "action": "shallow_clone",
            "gold_fqn": gold_fqn,
            "target": full_target,
            "pre_flip_ts": pre_flip_ts,
            "elapsed_ms": int((time.time() - started) * 1000),
            "ok": True,
        }
    except RuntimeError as exc:
        err = str(exc)
        if "cannot_shallow_clone_non_uc_managed" not in err.lower() and "shallow clone" not in err.lower():
            # Unexpected error — surface it
            return {
                "action": "clone_failed",
                "gold_fqn": gold_fqn,
                "target": full_target,
                "elapsed_ms": int((time.time() - started) * 1000),
                "ok": False,
                "error": err,
            }
        # Expected: external table — fall through to CTAS

    # CTAS fallback: create empty (or filtered) schema-matching managed table
    ctas_sql = (
        f"CREATE OR REPLACE TABLE {full_target} AS "
        f"SELECT * FROM {gold_fqn}{ts_clause} WHERE {baseline_filter}"
    )
    try:
        execute_sql(w, sql_text=ctas_sql, warehouse_id=wid, poll_deadline_sec=3600.0)
        return {
            "action": "ctas_fallback",
            "gold_fqn": gold_fqn,
            "target": full_target,
            "baseline_filter": baseline_filter,
            "pre_flip_ts": pre_flip_ts,
            "elapsed_ms": int((time.time() - started) * 1000),
            "ok": True,
        }
    except Exception as exc2:
        return {
            "action": "clone_failed",
            "gold_fqn": gold_fqn,
            "target": full_target,
            "elapsed_ms": int((time.time() - started) * 1000),
            "ok": False,
            "error": str(exc2),
        }


def drop_table(w: WorkspaceClient, wid: str, target_name: str) -> dict[str, Any]:
    """DROP the parallel clone after parity check (ephemeral lifecycle)."""
    full_target = f"{PARALLEL_SCHEMA}.{target_name}"
    try:
        execute_sql(
            w,
            sql_text=f"DROP TABLE IF EXISTS {full_target}",
            warehouse_id=wid,
        )
        return {"action": "dropped", "target": full_target, "ok": True}
    except Exception as exc:
        return {"action": "drop_failed", "target": full_target, "ok": False, "error": str(exc)}


# ---------------------------------------------------------------------------
# Routine rewrite + create
# ---------------------------------------------------------------------------

def _rewrite_body(body: str) -> str:
    """Rewrite proc body for execution in migration_parallel.

    1. Replace all ``migration_tables`` schema refs with ``migration_parallel``.
    2. Add ``IF EXISTS`` to bare ``DROP TABLE`` / ``DROP VIEW`` statements so the
       proc doesn't fail on a fresh schema where intermediate tables don't exist yet.
    """
    # Fully-qualified: dwh_daily_process.migration_tables. -> migration_parallel.
    out = re.sub(
        r"dwh_daily_process\.migration_tables\.",
        f"{PARALLEL_SCHEMA}.",
        body,
        flags=re.IGNORECASE,
    )
    # Bare schema-only references: migration_tables.X (safety net after above)
    out = re.sub(
        r"\bmigration_tables\.",
        "migration_parallel.",
        out,
        flags=re.IGNORECASE,
    )
    # Add IF EXISTS to bare DROP TABLE / DROP VIEW (safe for fresh schema).
    out = re.sub(r"\bDROP\s+TABLE\s+(?!IF\s+EXISTS)", "DROP TABLE IF EXISTS ", out, flags=re.IGNORECASE)
    out = re.sub(r"\bDROP\s+VIEW\s+(?!IF\s+EXISTS)", "DROP VIEW IF EXISTS ", out, flags=re.IGNORECASE)
    return out


def _build_create_proc_ddl(proc_name: str, params: list[tuple[str, str]], body: str) -> str:
    param_str = ", ".join(f"{n} {t}" for n, t in params)
    # Databricks SQL requires LANGUAGE SQL, SQL SECURITY INVOKER, and MODIFIES SQL DATA
    # for stored procedures that write data (INSERT, MERGE, UPDATE, DELETE).
    return (
        f"CREATE OR REPLACE PROCEDURE {PARALLEL_SCHEMA}.{proc_name}({param_str})\n"
        f"LANGUAGE SQL\n"
        f"SQL SECURITY INVOKER\n"
        f"MODIFIES SQL DATA\n"
        f"{body}"
    )


def _build_create_func_ddl(
    func_name: str,
    params: list[tuple[str, str]],
    return_type: str,
    body: str,
) -> str:
    param_str = ", ".join(f"{n} {t}" for n, t in params)
    # Databricks SQL scalar function: body = BEGIN RETURN ...; END  or bare RETURN expr
    if body.strip().upper().startswith("BEGIN"):
        return (
            f"CREATE OR REPLACE FUNCTION {PARALLEL_SCHEMA}.{func_name}({param_str})\n"
            f"RETURNS {return_type or 'STRING'}\n"
            f"{body}"
        )
    return (
        f"CREATE OR REPLACE FUNCTION {PARALLEL_SCHEMA}.{func_name}({param_str})\n"
        f"RETURNS {return_type or 'STRING'}\n"
        f"RETURN {body}"
    )


def materialize_routines(
    w: WorkspaceClient,
    wid: str,
    root_proc: str,
) -> list[dict[str, Any]]:
    """Walk proc graph, rewrite + CREATE OR REPLACE every routine in migration_parallel.

    Dependencies are created before callers (reversed BFS order).
    """
    graph = walk_call_graph(w, wid, root_proc)
    results: list[dict[str, Any]] = []

    for proc in reversed(graph):
        routine_result = _get_routine_body(w, wid, proc)
        if routine_result is None:
            # Should not happen (walk_call_graph now only adds procs with bodies),
            # but guard just in case.
            results.append({"routine": proc, "ok": True, "action": "skip", "reason": "body_not_found"})
            continue
        canonical_proc, body = routine_result

        routine_type, return_type, params = _get_routine_signature(w, wid, canonical_proc)
        new_body = _rewrite_body(body)

        if routine_type == "PROCEDURE":
            ddl = _build_create_proc_ddl(canonical_proc, params, new_body)
        else:
            ddl = _build_create_func_ddl(canonical_proc, params, return_type, new_body)

        started = time.time()
        try:
            execute_sql(w, sql_text=ddl, warehouse_id=wid, poll_deadline_sec=300.0)
            results.append({
                "routine": canonical_proc,
                "routine_type": routine_type,
                "ok": True,
                "elapsed_ms": int((time.time() - started) * 1000),
            })
        except Exception as exc:
            results.append({
                "routine": canonical_proc,
                "routine_type": routine_type,
                "ok": False,
                "error": str(exc),
                "elapsed_ms": int((time.time() - started) * 1000),
            })

    return results


# ---------------------------------------------------------------------------
# Main materialization entry point
# ---------------------------------------------------------------------------

@dataclass
class MaterializeResult:
    target_id: str
    clones: list[dict[str, Any]] = field(default_factory=list)
    routines: list[dict[str, Any]] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        bad_clone = any(not c["ok"] for c in self.clones)
        bad_routine = any(not r["ok"] for r in self.routines)
        return not bad_clone and not bad_routine

    def as_dict(self) -> dict[str, Any]:
        return {
            "target_id": self.target_id,
            "ok": self.ok,
            "clones": self.clones,
            "routines": self.routines,
        }


def materialize_target(
    w: WorkspaceClient,
    wid: str,
    *,
    target_id: str,
    gold_table: str,
    parallel_table_name: str,
    wrapper_proc: str,
    gold_overrides: dict[str, str] | None = None,
    schema_source_table: str | None = None,
    pre_flip_ts: str | None = None,
) -> MaterializeResult:
    """Full materialization for one target: clone gold + clone source deps + rewrite procs.

    Args:
        target_id:           Human label for logging.
        gold_table:          FQN of the live gold table to clone.
        parallel_table_name: Simple name (no schema) for the clone in migration_parallel.
        wrapper_proc:        Root proc in migration_tables to rewrite + create.
        gold_overrides:      Override map {lower(migration_table_name): gold_fqn} for
                             tables whose gold names deviate from convention.
        schema_source_table: When set, use this FQN (with filter 1=0) as the schema
                             source for the target table clone instead of gold_table.
                             Use when gold_table is a view with an older schema than
                             migration_tables (e.g. missing recently-added columns).
        pre_flip_ts:         When set (format 'YYYY-MM-DD HH:MM:SS'), all clones of
                             real-data tables use TIMESTAMP AS OF to pin to the
                             pre-flip state.  Pass '{run_date} 01:00:00' so clones
                             reflect D-2 state and proc increments are clean.
    """
    ensure_schema(w, wid)
    result = MaterializeResult(target_id=target_id)
    overrides = gold_overrides or {}

    # 1. Clone the target's own gold table
    clone_source = schema_source_table if schema_source_table else gold_table
    # schema_source_table clones are always 1=0 (schema-only) — no time-travel needed.
    clone_pts = None if schema_source_table else pre_flip_ts
    result.clones.append(clone_table(
        w, wid, gold_fqn=clone_source, target_name=parallel_table_name,
        pre_flip_ts=clone_pts,
    ))

    # 2. Walk call graph to discover all referenced source tables
    all_routines = _get_all_routine_names(w, wid)
    graph = walk_call_graph(w, wid, wrapper_proc)
    combined_body_parts: list[str] = []
    for proc in graph:
        routine_result = _get_routine_body(w, wid, proc)
        combined_body_parts.append(routine_result[1] if routine_result else "")
    combined_body = "\n".join(combined_body_parts)

    _, table_refs = _find_refs_in_body(combined_body, all_routines)
    for tbl in sorted(table_refs):
        low = tbl.lower()
        # Skip: the target table (already cloned above)
        if low == parallel_table_name.lower():
            continue

        # Skip: session-scoped runtime temp tables (_tmp_* / TEMP_TABLE_*).
        # These are created at proc runtime — not persistent tables to clone.
        if low.startswith("_tmp_") or low.startswith("temp_table_"):
            continue

        if low.startswith("ext_"):
            # Intermediate staging table: TRUNCATE+INSERT pattern.
            # Bootstrap an empty schema copy from migration_tables so TRUNCATE works.
            # skip_if_populated=False: Ext_ tables are always truncated by the proc.
            # No time-travel needed: baseline_filter="1=0" (schema-only).
            src = f"{MIGRATION_SCHEMA}.{tbl}"
            result.clones.append(
                clone_table(w, wid, gold_fqn=src, target_name=tbl, baseline_filter="1=0")
            )
            continue

        # Try to resolve a gold equivalent first.
        gold_fqn = resolve_verified_gold_fqn(w, wid, tbl, overrides)
        if gold_fqn is not None:
            # skip_if_populated=True: this table might have been written by a prior
            # ring (e.g. dim_country from Ring 0).  Never overwrite live ring data.
            # pre_flip_ts: pin dependency clones to pre-flip state — the proc may
            # join against these tables and expects D-2 baseline data.
            result.clones.append(
                clone_table(w, wid, gold_fqn=gold_fqn, target_name=tbl,
                            skip_if_populated=True, pre_flip_ts=pre_flip_ts)
            )
        else:
            # No gold equivalent found — bootstrap empty schema copy from migration_tables.
            # This handles Dim_X / Fact_X tables that are full-refresh outputs of the proc.
            # skip_if_populated=True: if a prior ring already wrote rows, keep them.
            # No time-travel: baseline_filter="1=0" (schema-only).
            src = f"{MIGRATION_SCHEMA}.{tbl}"
            result.clones.append(
                clone_table(w, wid, gold_fqn=src, target_name=tbl, baseline_filter="1=0",
                            skip_if_populated=True)
            )

    # 3. Rewrite + create all routines in migration_parallel
    result.routines = materialize_routines(w, wid, wrapper_proc)

    return result


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    import argparse
    import json

    ap = argparse.ArgumentParser(description="Materialize one target in migration_parallel.")
    ap.add_argument("--target-id", required=True, help="Human label for this target.")
    ap.add_argument("--gold-table", required=True, help="FQN gold table to SHALLOW CLONE.")
    ap.add_argument("--parallel-table-name", required=True, help="Name in migration_parallel.")
    ap.add_argument("--wrapper-proc", required=True, help="Root proc name in migration_tables.")
    ap.add_argument("--dry-run", action="store_true", help="Only print call graph, no changes.")
    args = ap.parse_args()

    w = make_workspace_client()
    wid = warehouse_id_from_env()

    if args.dry_run:
        graph = walk_call_graph(w, wid, args.wrapper_proc)
        print(json.dumps({"call_graph": graph}, indent=2))
        return 0

    result = materialize_target(
        w, wid,
        target_id=args.target_id,
        gold_table=args.gold_table,
        parallel_table_name=args.parallel_table_name,
        wrapper_proc=args.wrapper_proc,
    )
    print(json.dumps(result.as_dict(), indent=2, default=str))
    return 0 if result.ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
