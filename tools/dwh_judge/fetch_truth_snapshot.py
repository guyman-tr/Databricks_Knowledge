"""Fetch the DWH_dbo Tier-1 truth snapshot used by the LLM judge pipeline.

One-shot Synapse extraction into ``knowledge/_dwh_truth_snapshot/``:

  ddl.json           -- per-object column metadata (name, type, nullable,
                        default, ordinal) from INFORMATION_SCHEMA.COLUMNS
                        joined with sys.default_constraints. Includes views.
  sp_code.json       -- full body of every SP_* in DWH_dbo, from
                        sys.sql_modules. Used by the LLM stage to ground
                        Tier-2 derivation claims.
  fks.json           -- every FK constraint in DWH_dbo joined to parent /
                        referenced tables. Authoritative FK target list.
  upstream_index.json -- index of knowledge/skills/_de_existing/*.md content
                        keyed by (source_table, column-or-section) so the
                        deterministic verifier can resolve `Tier 1 - X.Y`
                        lineage tags.
  snapshot_meta.json  -- timestamp, host, db, counts, schema scope.

The existing ``knowledge/_dictionary_truth.json`` is the codepoint truth and
is reused as-is (extended in place by tools/fetch_dictionary_truth.py when
new Dim_* coverage is needed).

Usage:
    python tools/dwh_judge/fetch_truth_snapshot.py
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))
from synapse_connect import connect, run_query  # noqa: E402

OUT_DIR = REPO / "knowledge" / "_dwh_truth_snapshot"
UPSTREAM_SKILL_DIR = REPO / "knowledge" / "skills" / "_de_existing"
UPSTREAM_PRODSCHEMAS = REPO / "knowledge" / "ProdSchemas"

SCHEMA = "DWH_dbo"


def _fetch_ddl(conn) -> dict[str, dict]:
    """Return {object_name: {kind, columns: [{name, ordinal, type, nullable, default}]}}.

    Includes both tables and views. Default values come from sys.default_constraints
    joined on the column.
    """
    print(f"  [ddl] Fetching INFORMATION_SCHEMA.COLUMNS for schema {SCHEMA}...", flush=True)
    sql_cols = f"""
    SELECT
        c.TABLE_NAME       AS object_name,
        c.COLUMN_NAME      AS column_name,
        c.ORDINAL_POSITION AS ordinal,
        c.DATA_TYPE        AS data_type,
        c.CHARACTER_MAXIMUM_LENGTH AS char_max_len,
        c.NUMERIC_PRECISION        AS numeric_precision,
        c.NUMERIC_SCALE            AS numeric_scale,
        c.IS_NULLABLE      AS is_nullable,
        c.COLUMN_DEFAULT   AS column_default,
        t.TABLE_TYPE       AS table_type
    FROM INFORMATION_SCHEMA.COLUMNS c
    JOIN INFORMATION_SCHEMA.TABLES t
      ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
    WHERE c.TABLE_SCHEMA = '{SCHEMA}'
    ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION
    """
    cols, rows = run_query(conn, sql_cols)
    idx = {c: i for i, c in enumerate(cols)}
    out: dict[str, dict] = {}
    for r in rows:
        obj = r[idx["object_name"]]
        if obj not in out:
            out[obj] = {
                "kind": "VIEW" if r[idx["table_type"]] == "VIEW" else "TABLE",
                "columns": [],
            }
        out[obj]["columns"].append({
            "name": r[idx["column_name"]],
            "ordinal": r[idx["ordinal"]],
            "data_type": r[idx["data_type"]],
            "char_max_len": r[idx["char_max_len"]],
            "numeric_precision": r[idx["numeric_precision"]],
            "numeric_scale": r[idx["numeric_scale"]],
            "is_nullable": r[idx["is_nullable"]] == "YES",
            "column_default": r[idx["column_default"]],
        })
    print(f"  [ddl] {len(out)} objects, "
          f"{sum(len(v['columns']) for v in out.values())} columns", flush=True)
    return out


def _fetch_sp_code(conn) -> dict[str, str]:
    """Return {sp_name: definition_text} for every SP_* in DWH_dbo."""
    print(f"  [sp] Fetching sys.sql_modules for SP_* in {SCHEMA}...", flush=True)
    sql = f"""
    SELECT o.name AS sp_name, m.definition
    FROM sys.sql_modules m
    JOIN sys.objects o ON o.object_id = m.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = '{SCHEMA}'
      AND o.type = 'P'
      AND o.name LIKE 'SP[_]%'
    ORDER BY o.name
    """
    cols, rows = run_query(conn, sql)
    out: dict[str, str] = {}
    for r in rows:
        out[r[0]] = r[1] or ""
    print(f"  [sp] {len(out)} stored procedures captured", flush=True)
    return out


def _fetch_fks(conn) -> list[dict]:
    """Return list of {fk_name, parent_object, parent_column, referenced_object,
    referenced_column}, scoped to DWH_dbo as parent."""
    print(f"  [fk] Fetching sys.foreign_keys for schema {SCHEMA}...", flush=True)
    sql = f"""
    SELECT
        fk.name             AS fk_name,
        ps.name + '.' + pt.name AS parent_object,
        pc.name             AS parent_column,
        rs.name + '.' + rt.name AS referenced_object,
        rc.name             AS referenced_column
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    JOIN sys.tables  pt ON pt.object_id = fkc.parent_object_id
    JOIN sys.schemas ps ON ps.schema_id = pt.schema_id
    JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
    JOIN sys.tables  rt ON rt.object_id = fkc.referenced_object_id
    JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
    JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
    WHERE ps.name = '{SCHEMA}'
    ORDER BY pt.name, fk.name, pc.name
    """
    cols, rows = run_query(conn, sql)
    idx = {c: i for i, c in enumerate(cols)}
    out = []
    for r in rows:
        out.append({
            "fk_name": r[idx["fk_name"]],
            "parent_object": r[idx["parent_object"]],
            "parent_column": r[idx["parent_column"]],
            "referenced_object": r[idx["referenced_object"]],
            "referenced_column": r[idx["referenced_column"]],
        })
    print(f"  [fk] {len(out)} FK column edges captured", flush=True)
    return out


def _fetch_object_inventory(conn) -> dict[str, dict]:
    """Return {object_name: {kind, row_count_estimate}} for sanity-checking
    later (e.g., reject 'most rows' claims on empty tables)."""
    print(f"  [inv] Fetching row-count estimates for {SCHEMA}...", flush=True)
    sql = f"""
    SELECT
        t.name AS object_name,
        SUM(p.rows) AS row_count_estimate
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
    WHERE s.name = '{SCHEMA}'
    GROUP BY t.name
    """
    try:
        cols, rows = run_query(conn, sql)
        out = {r[0]: {"kind": "TABLE", "row_count_estimate": int(r[1] or 0)} for r in rows}
    except Exception as e:  # CCI tables / dedicated SQL pool quirks: skip silently
        print(f"  [inv] WARN: row-count estimate failed ({e}); continuing without it", flush=True)
        out = {}
    print(f"  [inv] {len(out)} table row-count estimates captured", flush=True)
    return out


def _index_upstream() -> dict[str, dict]:
    """Build two upstream indexes:

    - ``skill_files``  body text of every ``knowledge/skills/_de_existing/*.md``.
      Used by the LLM judge as supporting prose.
    - ``prod_tables``  every ``knowledge/ProdSchemas/**/Wiki/**/*.md`` whose
      filename matches ``<Schema>.<Table>.md``. Used by the deterministic
      verifier to resolve ``Tier 1 - upstream wiki, <Schema>.<Table>`` claims.
      Keyed by ``<Schema>.<Table>``; value is the relative wiki path.

    Returns ``{files, by_source_table, skill_files, prod_tables}``.
    """
    print(f"  [upstream] Indexing {UPSTREAM_SKILL_DIR}...", flush=True)
    skill_files: dict[str, str] = {}
    if UPSTREAM_SKILL_DIR.exists():
        for p in UPSTREAM_SKILL_DIR.rglob("*.md"):
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            try:
                skill_files[rel] = p.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
    print(f"  [upstream] {len(skill_files)} skill files indexed "
          f"({sum(len(t) for t in skill_files.values())} chars)", flush=True)

    print(f"  [upstream] Indexing {UPSTREAM_PRODSCHEMAS}...", flush=True)
    prod_tables: dict[str, str] = {}
    if UPSTREAM_PRODSCHEMAS.exists():
        for p in UPSTREAM_PRODSCHEMAS.rglob("*.md"):
            base = p.name[:-3]
            if base.startswith("_"):
                continue
            # Accept "Schema.Table" filenames (single dot, both halves
            # identifier-shaped) anywhere in the tree.
            parts = base.split(".")
            if len(parts) != 2:
                continue
            sch, tbl = parts
            if not (sch and tbl and sch[0].isalpha() and tbl[0].isalpha()):
                continue
            key = f"{sch}.{tbl}"
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            # Prefer the shallowest path on duplicates.
            if key not in prod_tables or len(rel) < len(prod_tables[key]):
                prod_tables[key] = rel
    print(f"  [upstream] {len(prod_tables)} production wiki files indexed",
          flush=True)

    # Keep legacy 'files' key for back-compat with the LLM judge prompt builder.
    return {
        "skill_files": skill_files,
        "prod_tables": prod_tables,
        "files": skill_files,  # alias for old callers
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Building DWH judge truth snapshot in {OUT_DIR.relative_to(REPO)}/", flush=True)

    conn = connect()
    try:
        ddl = _fetch_ddl(conn)
        sp_code = _fetch_sp_code(conn)
        fks = _fetch_fks(conn)
        inventory = _fetch_object_inventory(conn)
    finally:
        conn.close()

    upstream = _index_upstream()

    (OUT_DIR / "ddl.json").write_text(json.dumps(ddl, indent=2), encoding="utf-8")
    (OUT_DIR / "sp_code.json").write_text(json.dumps(sp_code, indent=2), encoding="utf-8")
    (OUT_DIR / "fks.json").write_text(json.dumps(fks, indent=2), encoding="utf-8")
    (OUT_DIR / "inventory.json").write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    (OUT_DIR / "upstream_index.json").write_text(
        json.dumps(upstream, indent=2), encoding="utf-8"
    )

    meta = {
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "schema": SCHEMA,
        "object_count": len(ddl),
        "column_count": sum(len(v["columns"]) for v in ddl.values()),
        "sp_count": len(sp_code),
        "fk_edge_count": len(fks),
        "upstream_skill_file_count": len(upstream.get("skill_files", {})),
        "upstream_prod_table_count": len(upstream.get("prod_tables", {})),
    }
    (OUT_DIR / "snapshot_meta.json").write_text(
        json.dumps(meta, indent=2), encoding="utf-8"
    )

    print("\nSnapshot written:")
    for k, v in meta.items():
        print(f"  {k:<22} {v}")
    print(f"\nFiles:")
    for f in sorted(OUT_DIR.glob("*.json")):
        size = f.stat().st_size
        print(f"  {f.name:<22} {size/1024:>8.1f} KB")


if __name__ == "__main__":
    main()
