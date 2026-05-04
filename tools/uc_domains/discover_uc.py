#!/usr/bin/env python3
"""
Phase 1 — UC Discovery for an acquired-company UC domain.

Expand schema patterns from a domain card into a complete UC inventory:
  schemas, tables, views, columns, types, format, location, row counts,
  per-column sample values (up to N distinct), and per-object first-N rows.

Output: one JSON file (default knowledge/uc_domains/{domain}/_discovery/uc_inventory.json).

Auth: same path as tools/dbx_query.py and the Databricks MCP server —
  ~/.databrickscfg profile via env DATABRICKS_MCP_PROFILE (fallback "guyman"),
  or env DATABRICKS_TOKEN as a PAT for headless use.

Usage:
  python tools/uc_domains/discover_uc.py \
      --domain spaceship \
      --pattern "spaceship.*" \
      --pattern "etoro_kpi.v_spaceship_*" \
      --pattern "etoro_kpi_prep.v_spaceship_*" \
      --pattern "bizops_output.bizops_output_spaceship_*" \
      --catalog main \
      --sample-rows 5 \
      --out knowledge/uc_domains/spaceship/_discovery/uc_inventory.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import os
import re
import sys
import time
from pathlib import Path

try:
    from databricks import sql as dbsql
except ImportError:
    print("Install: pip install databricks-sql-connector databricks-sdk", file=sys.stderr)
    sys.exit(1)


DEFAULT_HOSTNAME = "adb-5142916747090026.6.azuredatabricks.net"
DEFAULT_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

# Column-name regex flags that trigger PII masking on samples.
PII_NAME_RE = re.compile(
    r"(?i)(email|phone|mobile|address|ssn|iban|bic|swift|card|cvv|password|passport|ssn|nin)"
)


def parse_pattern(pattern: str) -> tuple[str, str]:
    """Split a 'schema.table_glob' pattern. Wildcards allowed in either part."""
    if "." not in pattern:
        raise ValueError(f"Pattern must be 'schema.table_glob', got: {pattern!r}")
    schema, table_glob = pattern.split(".", 1)
    return schema, table_glob


def resolve_objects(cur, catalog: str, patterns: list[tuple[str, str]]) -> list[dict]:
    """List all UC objects (tables + views) matching at least one (schema, table_glob)."""
    schemas = sorted({p[0] for p in patterns})
    schema_filter = ",".join(f"'{s}'" for s in schemas)

    sql = f"""
    SELECT table_schema, table_name, table_type, comment
    FROM system.information_schema.tables
    WHERE table_catalog = '{catalog}'
      AND table_schema IN ({schema_filter})
    ORDER BY table_schema, table_name
    """
    cur.execute(sql)
    rows = cur.fetchall()

    objects = []
    for r in rows:
        s, t, ttype, comment = r[0], r[1], r[2], r[3]
        for pschema, pglob in patterns:
            if pschema != s:
                continue
            if fnmatch.fnmatchcase(t, pglob) or fnmatch.fnmatchcase(t.lower(), pglob.lower()):
                objects.append({
                    "schema": s,
                    "name": t,
                    "table_type": ttype,
                    "uc_comment": comment,
                })
                break
    return objects


def fetch_columns(cur, catalog: str, objects: list[dict]) -> dict[tuple[str, str], list[dict]]:
    """Bulk fetch columns for all objects in a single information_schema query."""
    if not objects:
        return {}
    pairs = sorted({(o["schema"], o["name"]) for o in objects})
    schemas = sorted({p[0] for p in pairs})
    schema_filter = ",".join(f"'{s}'" for s in schemas)
    sql = f"""
    SELECT table_schema, table_name, column_name, ordinal_position,
           data_type, is_nullable, comment, partition_index
    FROM system.information_schema.columns
    WHERE table_catalog = '{catalog}'
      AND table_schema IN ({schema_filter})
    ORDER BY table_schema, table_name, ordinal_position
    """
    cur.execute(sql)
    rows = cur.fetchall()
    out: dict[tuple[str, str], list[dict]] = {}
    pair_set = set(pairs)
    for r in rows:
        s, t = r[0], r[1]
        if (s, t) not in pair_set:
            continue
        out.setdefault((s, t), []).append({
            "name": r[2],
            "ordinal": int(r[3]) if r[3] is not None else None,
            "type": r[4],
            "nullable": (r[5] == "YES" if r[5] is not None else None),
            "comment": r[6],
            "is_partition": (r[7] is not None),
        })
    return out


def quote_ident(s: str) -> str:
    return "`" + s.replace("`", "``") + "`"


def fully_qualified(catalog: str, schema: str, name: str) -> str:
    return f"{quote_ident(catalog)}.{quote_ident(schema)}.{quote_ident(name)}"


def fetch_describe_extended(cur, fq: str) -> dict:
    """Run DESCRIBE EXTENDED and pluck format/location/owner/createdAt."""
    out = {"format": None, "location": None, "owner": None, "created_at": None, "table_properties": None}
    try:
        cur.execute(f"DESCRIBE EXTENDED {fq}")
        rows = cur.fetchall()
    except Exception as e:
        out["describe_error"] = str(e)
        return out
    in_detailed = False
    for r in rows:
        col = (r[0] or "").strip() if r[0] is not None else ""
        val = (r[1] or "").strip() if r[1] is not None else ""
        if col.startswith("# Detailed Table Information"):
            in_detailed = True
            continue
        if not in_detailed:
            continue
        low = col.lower()
        if low in ("provider", "format"):
            out["format"] = val
        elif low == "location":
            out["location"] = val
        elif low == "owner":
            out["owner"] = val
        elif low in ("created", "created time"):
            out["created_at"] = val
        elif low == "table properties":
            out["table_properties"] = val
    return out


def fetch_sample_rows(cur, fq: str, n: int) -> list[dict] | None:
    try:
        cur.execute(f"SELECT * FROM {fq} LIMIT {n}")
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
    except Exception as e:
        return [{"_error": str(e)[:300]}]
    out = []
    for r in rows:
        rec = {}
        for c, v in zip(cols, r):
            if PII_NAME_RE.search(c):
                rec[c] = "<masked>" if v is not None else None
            else:
                rec[c] = json_safe(v)
        out.append(rec)
    return out


def fetch_per_column_samples(cur, fq: str, columns: list[dict], n: int) -> dict[str, list]:
    """Per-column distinct-sample fetch, one query per column. Skip on PII."""
    out: dict[str, list] = {}
    for col in columns:
        cname = col["name"]
        if PII_NAME_RE.search(cname):
            out[cname] = ["<masked>"]
            continue
        try:
            cur.execute(
                f"SELECT DISTINCT {quote_ident(cname)} FROM {fq} "
                f"WHERE {quote_ident(cname)} IS NOT NULL LIMIT {n}"
            )
            rows = cur.fetchall()
            out[cname] = [json_safe(r[0]) for r in rows]
        except Exception as e:
            out[cname] = [f"<error: {str(e)[:120]}>"]
    return out


def fetch_row_count(cur, fq: str, table_type: str) -> int | None:
    if "VIEW" in (table_type or "").upper():
        return None
    try:
        cur.execute(f"SELECT COUNT(*) FROM {fq}")
        r = cur.fetchone()
        return int(r[0]) if r else None
    except Exception:
        return None


def json_safe(v):
    if v is None:
        return None
    if isinstance(v, (str, int, float, bool)):
        return v
    if isinstance(v, (dt.date, dt.datetime, dt.time)):
        return v.isoformat()
    if isinstance(v, (bytes, bytearray)):
        return f"<bytes:{len(v)}>"
    if isinstance(v, (list, tuple)):
        return [json_safe(x) for x in v]
    if isinstance(v, dict):
        return {str(k): json_safe(x) for k, x in v.items()}
    return str(v)


def connect():
    """Open a single databricks.sql connection.

    Auth resolution order — same as tools/dbx_query.py + skills/databricks-connection:
      1. DATABRICKS_TOKEN env (PAT) — for headless/CI.
      2. ~/.databrickscfg profile via SDK Config (matches MCP server). Profile from
         DATABRICKS_MCP_PROFILE → DATABRICKS_CONFIG_PROFILE → 'guyman' → 'DEFAULT'.
      3. databricks-sql-connector built-in U2M OAuth (browser pop-up). Last resort —
         this is what failed with 'No path parameters were returned to the callback'
         when port 8020 was unreachable.
    """
    hostname = os.environ.get("DATABRICKS_SERVER_HOSTNAME") or DEFAULT_HOSTNAME
    http_path = os.environ.get("DATABRICKS_HTTP_PATH") or DEFAULT_HTTP_PATH

    token = os.environ.get("DATABRICKS_TOKEN")
    if token:
        print(f"[connect] host={hostname} http_path={http_path} auth=PAT",
              file=sys.stderr, flush=True)
        return dbsql.connect(server_hostname=hostname, http_path=http_path, access_token=token)

    profile = (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "guyman"
    )
    try:
        from databricks.sdk.core import Config
        cfg = Config(profile=profile)
        print(f"[connect] host={hostname} http_path={http_path} auth=SDK profile={profile}",
              file=sys.stderr, flush=True)
        return dbsql.connect(
            server_hostname=hostname,
            http_path=http_path,
            credentials_provider=lambda: cfg.authenticate,
        )
    except Exception as e:
        print(f"[connect] SDK profile auth failed ({e}); falling back to U2M OAuth",
              file=sys.stderr, flush=True)

    return dbsql.connect(server_hostname=hostname, http_path=http_path, auth_type="databricks-oauth")


def main() -> int:
    ap = argparse.ArgumentParser(description="UC discovery for an acquired-company domain")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--pattern", action="append", required=True,
                    help="Repeatable. Format: 'schema.table_glob'. Wildcards: * ?")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--sample-rows", type=int, default=5)
    ap.add_argument("--per-column-samples", type=int, default=0,
                    help="Distinct values per column to sample. 0 to skip (default — use sample_rows). "
                         "Setting >0 multiplies query count by columns_per_table; expensive.")
    ap.add_argument("--row-counts", action="store_true", default=True,
                    help="Compute COUNT(*) per table (skipped for views)")
    ap.add_argument("--no-row-counts", dest="row_counts", action="store_false")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    patterns = [parse_pattern(p) for p in args.pattern]
    print(f"[discover] domain={args.domain} catalog={args.catalog} patterns={patterns}",
          file=sys.stderr, flush=True)

    t0 = time.time()
    conn = connect()
    cur = conn.cursor()

    objects = resolve_objects(cur, args.catalog, patterns)
    print(f"[discover] resolved {len(objects)} objects across "
          f"{len({o['schema'] for o in objects})} schemas", file=sys.stderr, flush=True)

    cols_map = fetch_columns(cur, args.catalog, objects)

    schemas: dict[str, dict] = {}
    n_total = len(objects)
    for i, obj in enumerate(objects, 1):
        s, t = obj["schema"], obj["name"]
        fq = fully_qualified(args.catalog, s, t)
        print(f"  [{i}/{n_total}] {s}.{t}", file=sys.stderr, flush=True)
        cols = cols_map.get((s, t), [])
        deinfo = fetch_describe_extended(cur, fq)

        row_count = None
        if args.row_counts:
            row_count = fetch_row_count(cur, fq, obj["table_type"])

        sample_rows = None
        if args.sample_rows > 0:
            sample_rows = fetch_sample_rows(cur, fq, args.sample_rows)

        per_col: dict[str, list] = {}
        if args.per_column_samples > 0:
            per_col = fetch_per_column_samples(cur, fq, cols, args.per_column_samples)
        elif sample_rows:
            for row in sample_rows:
                if not isinstance(row, dict):
                    continue
                for k, v in row.items():
                    if v is None:
                        continue
                    bucket = per_col.setdefault(k, [])
                    if v not in bucket and len(bucket) < args.sample_rows:
                        bucket.append(v)

        cols_out = []
        for c in cols:
            cols_out.append({
                **c,
                "samples": per_col.get(c["name"], []),
            })

        sch = schemas.setdefault(s, {"object_count": 0, "objects": []})
        sch["object_count"] += 1
        sch["objects"].append({
            "name": t,
            "full_name": f"{args.catalog}.{s}.{t}",
            "table_type": obj["table_type"],
            "format": deinfo.get("format"),
            "location": deinfo.get("location"),
            "owner": deinfo.get("owner"),
            "created_at": deinfo.get("created_at"),
            "uc_comment": obj.get("uc_comment"),
            "row_count": row_count,
            "column_count": len(cols),
            "columns": cols_out,
            "sample_rows": sample_rows,
            "describe_error": deinfo.get("describe_error"),
        })

    cur.close()
    conn.close()

    objects_total = sum(s["object_count"] for s in schemas.values())
    tables_total = sum(1 for s in schemas.values() for o in s["objects"]
                       if "VIEW" not in (o.get("table_type") or "").upper())
    views_total = objects_total - tables_total
    columns_total = sum(o["column_count"] for s in schemas.values() for o in s["objects"])
    cols_with_comment = sum(
        1 for s in schemas.values() for o in s["objects"] for c in o["columns"]
        if c.get("comment")
    )
    objs_with_comment = sum(1 for s in schemas.values() for o in s["objects"] if o.get("uc_comment"))

    payload = {
        "domain": args.domain,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "catalog": args.catalog,
        "patterns": [".".join(p) for p in patterns],
        "schemas": schemas,
        "stats": {
            "objects_total": objects_total,
            "tables": tables_total,
            "views": views_total,
            "columns_total": columns_total,
            "columns_with_uc_comment": cols_with_comment,
            "objects_with_uc_comment": objs_with_comment,
            "wall_seconds": round(time.time() - t0, 1),
        },
    }
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[discover] wrote {out_path} ({out_path.stat().st_size:,} bytes; "
          f"{objects_total} objects, {columns_total} columns, "
          f"{payload['stats']['wall_seconds']}s)", file=sys.stderr, flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
