"""
Pull view DDL from main.{etoro_kpi, etoro_kpi_prep, etoro_kpi_prep_stg, etoro_kpi_stg}
and parse FROM/JOIN clauses to emit edges.

Output:
  knowledge/skills/_edges_kpi.csv          (etoro_kpi schema)
  knowledge/skills/_edges_kpi_prep.csv     (etoro_kpi_prep + _stg schemas)
  knowledge/skills/_kpi_views_index.json   (view list with their referenced objects)
"""
from __future__ import annotations

import csv
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_KPI = ROOT / "knowledge" / "skills" / "_edges_kpi.csv"
OUT_PREP = ROOT / "knowledge" / "skills" / "_edges_kpi_prep.csv"
OUT_INDEX = ROOT / "knowledge" / "skills" / "_kpi_views_index.json"

try:
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.service.sql import StatementState
except ImportError:
    print("Install: pip install databricks-sdk", file=sys.stderr)
    sys.exit(1)


def profile() -> str:
    return (
        os.environ.get("DATABRICKS_MCP_PROFILE")
        or os.environ.get("DATABRICKS_CONFIG_PROFILE")
        or "DEFAULT"
    )


WAREHOUSE_ID = "208214768b0e0308"


def run_query(w: WorkspaceClient, sql: str, timeout_s: int = 120) -> tuple[list[str], list[list]]:
    import time

    resp = w.statement_execution.execute_statement(
        statement=sql,
        warehouse_id=WAREHOUSE_ID,
        wait_timeout="30s",
    )
    sid = resp.statement_id
    deadline = time.time() + timeout_s
    while resp.status.state not in (
        StatementState.SUCCEEDED,
        StatementState.FAILED,
        StatementState.CANCELED,
        StatementState.CLOSED,
    ):
        if time.time() > deadline:
            raise TimeoutError(sql[:80])
        time.sleep(2.0)
        resp = w.statement_execution.get_statement(sid)
    if resp.status.state != StatementState.SUCCEEDED:
        raise RuntimeError(f"State={resp.status.state} err={resp.status.error}")
    if not resp.manifest or not resp.result:
        return [], []
    cols = [c.name for c in resp.manifest.schema.columns]
    data = resp.result.data_array or []
    return cols, data


# Match table refs after FROM or JOIN. Catches:
#   FROM main.etoro_kpi_prep.foo
#   FROM `main`.`etoro_kpi_prep`.`foo`
#   JOIN dwh.dim_customer
#   JOIN main.etoro_kpi_prep.foo AS bar
#   FROM hive_metastore.foo.bar
# Skips subqueries (FROM (SELECT...))
TABLE_REF = re.compile(
    r"\b(?:FROM|JOIN)\s+"  # FROM/JOIN keyword
    r"(?!\(|LATERAL\b|UNNEST\b)"  # not subquery
    r"((?:`[^`]+`|[A-Za-z_][\w]*)"  # first segment
    r"(?:\s*\.\s*(?:`[^`]+`|[A-Za-z_][\w]*)){0,2})",  # 0-2 more segments
    re.IGNORECASE,
)


def normalize_ref(raw: str) -> str | None:
    """Normalize a parsed reference into 'schema.object' form (last 2 segments)."""
    parts = [p.strip().strip("`") for p in raw.split(".")]
    parts = [p for p in parts if p]
    if not parts:
        return None
    if len(parts) == 1:
        return parts[0]  # bare alias - useful for traceability
    return f"{parts[-2]}.{parts[-1]}"


def strip_sql_noise(sql: str) -> str:
    """Strip block comments and line comments, normalize whitespace."""
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    sql = re.sub(r"--[^\n]*", " ", sql)
    sql = re.sub(r"\s+", " ", sql)
    return sql


def parse_refs(sql: str) -> list[str]:
    cleaned = strip_sql_noise(sql)
    refs = []
    for m in TABLE_REF.finditer(cleaned):
        ref = normalize_ref(m.group(1))
        if ref:
            refs.append(ref)
    return refs


def main() -> int:
    OUT_KPI.parent.mkdir(parents=True, exist_ok=True)
    print(f"Profile={profile()}, Warehouse={WAREHOUSE_ID}", flush=True)
    w = WorkspaceClient(profile=profile())

    schemas = ["etoro_kpi", "etoro_kpi_prep", "etoro_kpi_prep_stg", "etoro_kpi_stg"]
    schema_list = ",".join(f"'{s}'" for s in schemas)
    sql = (
        "SELECT table_schema, table_name, view_definition "
        "FROM main.information_schema.views "
        f"WHERE table_schema IN ({schema_list}) "
        "ORDER BY table_schema, table_name"
    )
    print(f"Fetching view definitions for schemas: {schemas}", flush=True)
    cols, rows = run_query(w, sql, timeout_s=180)
    print(f"Got {len(rows)} view definitions", flush=True)

    kpi_edges = []
    prep_edges = []
    index = []

    for row in rows:
        schema, name, ddl = row[0], row[1], row[2] or ""
        self_ref = f"{schema}.{name}"
        refs = parse_refs(ddl)
        # dedupe but keep order for the index
        seen = []
        for r in refs:
            if r not in seen:
                seen.append(r)
        index.append({
            "schema": schema,
            "name": name,
            "self_ref": self_ref,
            "refs": seen,
            "ddl_chars": len(ddl),
        })
        for r in seen:
            if r == self_ref:
                continue
            edge = {
                "left": self_ref,
                "right": r,
                "edge_kind": "kpi_view_dep" if schema in {"etoro_kpi"} else "kpi_prep_view_dep",
                "join_keys": "",
                "purpose": "",
                "source": schema,
            }
            (kpi_edges if schema == "etoro_kpi" else prep_edges).append(edge)

    fields = ["left", "right", "edge_kind", "join_keys", "purpose", "source"]
    for path, edges, label in [
        (OUT_KPI, kpi_edges, "kpi"),
        (OUT_PREP, prep_edges, "kpi_prep"),
    ]:
        with path.open("w", encoding="utf-8", newline="") as f:
            wcsv = csv.DictWriter(f, fieldnames=fields)
            wcsv.writeheader()
            for e in edges:
                wcsv.writerow(e)
        print(f"Wrote {path.relative_to(ROOT)} ({len(edges)} edges, {label})", flush=True)

    OUT_INDEX.write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"Wrote {OUT_INDEX.relative_to(ROOT)} ({len(index)} views)", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
