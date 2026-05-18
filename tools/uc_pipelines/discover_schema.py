#!/usr/bin/env python3
"""
Phases 0 & 1 — Schema Card + UC Discovery (UC-Pipeline pack).

Combines two related passes against a single UC schema:

  --phase 0  (default): enumerate the schema, classify each object's writer via
             system.access.table_lineage, and emit `_schema_card.md` with the
             in-scope / out-of-scope decision per object.

  --phase 1: emit the full per-object inventory (columns + DESCRIBE EXTENDED +
             samples + view_definition) for every in-scope object the card
             listed.

Outputs land under `knowledge/UC_generated/{schema}/`:

  _schema_card.md                       (phase 0)
  _discovery/uc_inventory.json          (phase 1)

Auth: same path as tools/uc_domains/discover_uc.py — see tools/uc_pipelines/_conn.py.

Usage:
  python tools/uc_pipelines/discover_schema.py --schema etoro_kpi_prep
  python tools/uc_pipelines/discover_schema.py --schema etoro_kpi_prep --phase 1 --sample-rows 5
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from uc_pipelines._conn import connect  # noqa: E402


# ---- PII masking (column-name pattern only — same as discover_uc.py) ----
PII_NAME_RE = re.compile(
    r"(?i)(email|phone|mobile|address|ssn|iban|bic|swift|card|cvv|password|passport|nin)"
)

OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"

# Schemas owned by other packs (never in-scope here)
BRONZE_SCHEMA_HINTS = {"general", "trading", "billing", "emoney", "mixpanel",
                       "spaceship", "moneyfarm", "fiatdwhdb"}
GOLD_MIRROR_PREFIX = "gold_sql_dp_prod_we_"


# ============================== helpers ==============================

def quote_ident(s: str) -> str:
    return "`" + s.replace("`", "``") + "`"


def fully_qualified(catalog: str, schema: str, name: str) -> str:
    return f"{quote_ident(catalog)}.{quote_ident(schema)}.{quote_ident(name)}"


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


# ============================== phase 0 ==============================

def list_schema_objects(cur, catalog: str, schema: str) -> list[dict]:
    sql = f"""
    SELECT table_name, table_type, comment
    FROM system.information_schema.tables
    WHERE table_catalog = '{catalog}'
      AND table_schema  = '{schema}'
    ORDER BY table_name
    """
    cur.execute(sql)
    rows = cur.fetchall()
    return [{"name": r[0], "table_type": r[1], "uc_comment": r[2]} for r in rows]


def fetch_view_definitions(cur, catalog: str, schema: str) -> dict[str, str]:
    """Bulk-pull view_definition for every view/materialized view in the schema."""
    sql = f"""
    SELECT table_name, view_definition
    FROM system.information_schema.views
    WHERE table_catalog = '{catalog}'
      AND table_schema  = '{schema}'
    """
    try:
        cur.execute(sql)
        return {r[0]: (r[1] or "") for r in cur.fetchall()}
    except Exception as e:
        print(f"[phase0] view_definition fetch failed: {e}", file=sys.stderr)
        return {}


def fetch_table_lineage_writers(cur, full_name: str, lookback_days: int) -> list[dict]:
    """Resolve the producer(s) of a TABLE via system.access.table_lineage.

    Returns one row per (entity_type, entity_id). Empty list when nothing in the
    lookback window — the caller flags such objects out-of-scope.
    """
    # The lineage view has source_table_full_name rows that are NULL for the
    # actual entity (notebook/job) — we group by entity dimensions only.
    sql = f"""
    SELECT
      entity_type,
      entity_id,
      MAX(workspace_id)   AS workspace_id,
      COUNT(*)            AS event_count,
      MIN(event_time)     AS first_event_time,
      MAX(event_time)     AS last_event_time
    FROM system.access.table_lineage
    WHERE lower(target_table_full_name) = lower('{full_name}')
      AND event_time > current_date - INTERVAL {lookback_days} DAYS
      AND entity_type IS NOT NULL
    GROUP BY entity_type, entity_id
    ORDER BY event_count DESC
    LIMIT 50
    """
    try:
        cur.execute(sql)
        return [{
            "entity_type": r[0],
            "entity_id": r[1],
            "workspace_id": json_safe(r[2]),
            "event_count": int(r[3]) if r[3] is not None else 0,
            "first_event_time": json_safe(r[4]),
            "last_event_time": json_safe(r[5]),
        } for r in cur.fetchall()]
    except Exception as e:
        print(f"[phase0] lineage fetch failed for {full_name}: {e}", file=sys.stderr)
        return []


def classify_writer(obj_name: str, table_type: str, view_def: str | None,
                    lineage_rows: list[dict],
                    upstream_wiki_hit: dict | None = None) -> dict:
    """Decide writer.kind + in_scope per the rules in 00-schema-card.mdc.

    `upstream_wiki_hit` is the entry for this object's FQN in
    _upstream_wiki_index.json (None if no match). When the object is a bronze
    table whose Tier 1 wiki is available, this flips it to in-scope with a
    `BRONZE_TIER1_INHERITANCE` writer instead of the default `BRONZE_INGEST`."""
    ttype = (table_type or "").upper()

    if "VIEW" in ttype:
        if not view_def:
            return {"kind": "UNKNOWN", "in_scope": False,
                    "reason": "VIEW has empty view_definition (catalog metadata broken)"}
        return {"kind": "view_definition", "in_scope": True}

    # TABLEs: check for out-of-scope patterns first
    if obj_name.startswith(GOLD_MIRROR_PREFIX):
        return {"kind": "GENERIC_PIPELINE", "in_scope": False,
                "reason": "synapse gold mirror — documented by dwh-semantic-doc"}
    if obj_name.startswith("bronze_"):
        # If a Tier 1 wiki is available, we CAN document this bronze table by
        # full inheritance from the upstream production wiki.
        if upstream_wiki_hit and upstream_wiki_hit.get("wiki_kind") == "bronze_tier1":
            return {
                "kind": "BRONZE_TIER1_INHERITANCE",
                "in_scope": True,
                "upstream_wiki_path": upstream_wiki_hit.get("wiki_path"),
                "source_database": upstream_wiki_hit.get("source_database"),
                "source_schema": upstream_wiki_hit.get("source_schema"),
                "source_table": upstream_wiki_hit.get("source_table"),
                "source_repo": upstream_wiki_hit.get("source_repo"),
                "datalake_path": upstream_wiki_hit.get("datalake_path"),
                "copy_strategy": upstream_wiki_hit.get("copy_strategy"),
            }
        return {"kind": "BRONZE_INGEST", "in_scope": False,
                "reason": "bronze ingest layer — no Tier 1 wiki available in upstream_wiki_index"}

    if not lineage_rows:
        return {"kind": "UNKNOWN", "in_scope": False,
                "reason": "no Spark-write producer in system.access.table_lineage (likely bronze ingest or stale)"}

    # Pick the highest-event-count entity. Ad-hoc QUERY producers get downgraded.
    primary = lineage_rows[0]
    et = (primary["entity_type"] or "").upper()
    classification = {
        "NOTEBOOK": "NOTEBOOK",
        "JOB": "JOB",
        "PIPELINE": "PIPELINE",
        "UC_FUNCTION": "UC_FUNCTION",
        "QUERY": "QUERY",
    }.get(et, et or "UNKNOWN")

    if classification == "QUERY":
        return {"kind": "QUERY", "in_scope": False,
                "reason": "writer is ad-hoc SQL editor QUERY (not a reproducible pipeline)",
                "lineage_rows": lineage_rows[:5]}

    if classification == "UNKNOWN":
        return {"kind": "UNKNOWN", "in_scope": False,
                "reason": f"unrecognised entity_type={primary['entity_type']}",
                "lineage_rows": lineage_rows[:5]}

    return {
        "kind": classification,
        "path": primary["entity_id"],
        "lineage_source": "system.access.table_lineage",
        "lineage_event_count": primary["event_count"],
        "in_scope": True,
        "additional_producers": [r for r in lineage_rows[1:5]] if len(lineage_rows) > 1 else [],
    }


def hint_upstreams_from_view_def(view_def: str | None, max_n: int = 12) -> list[str]:
    """Cheap regex-extract of `FROM`/`JOIN` target table names from a view DDL.

    Phase 4 does proper sqlglot parsing; here we just want a "looks plausible"
    list for the schema card. We don't worry about CTEs / subqueries.
    """
    if not view_def:
        return []
    pattern = re.compile(r"\b(?:FROM|JOIN)\s+([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+){1,2})", re.IGNORECASE)
    seen: list[str] = []
    for m in pattern.finditer(view_def):
        ref = m.group(1)
        if ref.lower() in {"information_schema"}:
            continue
        if ref not in seen:
            seen.append(ref)
        if len(seen) >= max_n:
            break
    return seen


# ============================== schema card render ==============================

def _frontmatter_block(payload: dict) -> str:
    """Render YAML frontmatter manually (avoid pulling a yaml dep just for this)."""
    def emit(v, indent=0):
        pad = "  " * indent
        if isinstance(v, dict):
            out = []
            for k, vv in v.items():
                if isinstance(vv, (dict, list)):
                    out.append(f"{pad}{k}:")
                    out.append(emit(vv, indent + 1))
                else:
                    out.append(f"{pad}{k}: {_yaml_scalar(vv)}")
            return "\n".join(out)
        if isinstance(v, list):
            if not v:
                return f"{pad}[]"
            lines = []
            for item in v:
                if isinstance(item, dict):
                    first = True
                    for k, vv in item.items():
                        prefix = f"{pad}- " if first else f"{pad}  "
                        first = False
                        if isinstance(vv, (dict, list)):
                            lines.append(f"{prefix}{k}:")
                            lines.append(emit(vv, indent + 2))
                        else:
                            lines.append(f"{prefix}{k}: {_yaml_scalar(vv)}")
                else:
                    lines.append(f"{pad}- {_yaml_scalar(item)}")
            return "\n".join(lines)
        return f"{pad}{_yaml_scalar(v)}"

    return "---\n" + emit(payload) + "\n---"


def _yaml_scalar(v) -> str:
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v)
    # Quote when needed
    if any(ch in s for ch in [":", "#", "\n", "'", '"', "{", "}", "[", "]"]) or s != s.strip():
        return '"' + s.replace('"', '\\"') + '"'
    return s


def render_schema_card(schema: str, catalog: str, objects: list[dict],
                       lookback_days: int) -> str:
    ts = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    in_scope = [o for o in objects if o["writer"].get("in_scope")]
    out_of_scope = [o for o in objects if not o["writer"].get("in_scope")]

    # Build YAML payload
    yaml_objects = []
    for obj in objects:
        w = obj["writer"]
        entry = {
            "name": obj["name"],
            "full_name": f"{catalog}.{schema}.{obj['name']}",
            "type": obj["table_type"],
            "writer": {k: v for k, v in w.items() if k != "in_scope" and v not in (None, [], "")},
            "in_scope": bool(w.get("in_scope")),
        }
        if not w.get("in_scope"):
            entry["reason"] = w.get("reason")
        # Hint upstreams for VIEWs from the cached DDL — helps human review of the card.
        if obj.get("upstreams_hint"):
            entry["upstreams_hint"] = obj["upstreams_hint"]
            entry["refs_source"] = "view_definition (regex extract)"
        yaml_objects.append(entry)

    fm = {
        "schema": schema,
        "catalog": catalog,
        "display_name": f"{schema} — UC-Pipeline scope sheet",
        "framework": "uc-pipeline-doc",
        "generated_at": ts,
        "lineage_lookback_days": lookback_days,
        "in_scope_count": len(in_scope),
        "out_of_scope_count": len(out_of_scope),
        "objects": yaml_objects,
    }

    parts: list[str] = []
    parts.append(_frontmatter_block(fm))
    parts.append("")
    parts.append(f"# {schema} — Schema Card")
    parts.append("")
    parts.append(f"> UC-Pipeline scope sheet for `{catalog}.{schema}`. "
                 f"**{len(in_scope)} in-scope** / **{len(out_of_scope)} out-of-scope** "
                 f"objects (lookback `{lookback_days}` days).")
    parts.append("")
    parts.append("## What this schema is")
    parts.append("")
    parts.append("_TODO (human): one paragraph on what role this UC schema plays in the eToro namespace, what is downstream of it._")
    parts.append("")
    parts.append("## In-scope objects")
    parts.append("")
    if in_scope:
        parts.append("| Object | Type | Writer | Producer |")
        parts.append("|--------|------|--------|----------|")
        for obj in in_scope:
            w = obj["writer"]
            wpath = w.get("path") or w.get("kind")
            parts.append(f"| `{obj['name']}` | `{obj['table_type']}` | `{w.get('kind')}` | `{wpath}` |")
    else:
        parts.append("_No in-scope objects — schema is fully out-of-scope or producers are unresolved._")
    parts.append("")
    parts.append("## Out-of-scope objects")
    parts.append("")
    if out_of_scope:
        parts.append("| Object | Type | Reason |")
        parts.append("|--------|------|--------|")
        for obj in out_of_scope:
            parts.append(f"| `{obj['name']}` | `{obj['table_type']}` | {obj['writer'].get('reason')} |")
    else:
        parts.append("_All objects in-scope._")
    parts.append("")
    parts.append("## Authoring policy")
    parts.append("")
    parts.append("Wikis under this folder follow the **UC-pipeline Tier 1–4 policy** "
                 "(`.cursor/rules/uc-pipeline-doc/05-generate-doc.mdc`). Passthrough columns "
                 "inherit their description **byte-for-byte** from the upstream wiki, "
                 "preserving the upstream's `(Tier N — origin)` tag — see "
                 "`GATE-lineage-contract.mdc` for the transitivity rule.")
    parts.append("")
    return "\n".join(parts)


# ============================== phase 1 ==============================

def fetch_columns(cur, catalog: str, schema: str, objects: list[dict]) -> dict[str, list[dict]]:
    """Bulk-fetch columns for all in-scope objects of one schema."""
    names = [o["name"] for o in objects]
    if not names:
        return {}
    name_filter = ",".join(f"'{n}'" for n in names)
    sql = f"""
    SELECT table_name, column_name, ordinal_position,
           data_type, is_nullable, comment, partition_index
    FROM system.information_schema.columns
    WHERE table_catalog = '{catalog}'
      AND table_schema  = '{schema}'
      AND table_name IN ({name_filter})
    ORDER BY table_name, ordinal_position
    """
    cur.execute(sql)
    out: dict[str, list[dict]] = {}
    for r in cur.fetchall():
        out.setdefault(r[0], []).append({
            "name": r[1],
            "ordinal": int(r[2]) if r[2] is not None else None,
            "type": r[3],
            "nullable": (r[4] == "YES" if r[4] is not None else None),
            "comment": r[5],
            "is_partition": (r[6] is not None),
        })
    return out


def fetch_describe_extended(cur, fq: str) -> dict:
    out = {"format": None, "location": None, "owner": None,
           "created_at": None, "table_properties": None}
    try:
        cur.execute(f"DESCRIBE EXTENDED {fq}")
        rows = cur.fetchall()
    except Exception as e:
        out["describe_error"] = str(e)[:300]
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


def fetch_row_count(cur, fq: str, table_type: str) -> int | None:
    if "VIEW" in (table_type or "").upper():
        return None
    try:
        cur.execute(f"SELECT COUNT(*) FROM {fq}")
        r = cur.fetchone()
        return int(r[0]) if r else None
    except Exception:
        return None


# ============================== main ==============================

def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline schema card + discovery")
    ap.add_argument("--schema", required=True, help="UC schema name (e.g. etoro_kpi_prep)")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--phase", choices=["0", "1", "both"], default="0",
                    help="0 = build schema card only; 1 = build uc_inventory only (requires existing card); "
                         "both = run phase 0 then phase 1 sequentially")
    ap.add_argument("--force", action="store_true",
                    help="Rebuild outputs even if they already exist")
    ap.add_argument("--lineage-lookback-days", type=int, default=90)
    ap.add_argument("--sample-rows", type=int, default=5,
                    help="Only used in phase 1")
    ap.add_argument("--row-counts", action="store_true", default=True)
    ap.add_argument("--no-row-counts", dest="row_counts", action="store_false")
    ap.add_argument("--objects", nargs="+", default=None,
                    help="Phase-1 only: restrict the inventory pass to a subset of in-scope objects.")
    ap.add_argument("--no-samples", action="store_true",
                    help="Phase-1 only: skip sample-row fetching (sample_rows=0)")
    ap.add_argument("--out", default=None,
                    help="Override output path. Default: "
                         "knowledge/UC_generated/{schema}/_schema_card.md (phase 0) "
                         "or knowledge/UC_generated/{schema}/_discovery/uc_inventory.json (phase 1).")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    schema_root.mkdir(parents=True, exist_ok=True)

    phase_str = str(args.phase)
    do_phase0 = phase_str in ("0", "both")
    do_phase1 = phase_str in ("1", "both")

    p0_out = Path(args.out) if (args.out and phase_str == "0") else schema_root / "_schema_card.md"
    p1_out = Path(args.out) if (args.out and phase_str == "1") else schema_root / "_discovery" / "uc_inventory.json"
    p0_out.parent.mkdir(parents=True, exist_ok=True)
    p1_out.parent.mkdir(parents=True, exist_ok=True)

    if not args.force:
        if do_phase0 and p0_out.exists():
            print(f"[discover-schema] phase=0 skip: {p0_out} exists (pass --force to rebuild)",
                  file=sys.stderr, flush=True)
            do_phase0 = False
        if do_phase1 and p1_out.exists():
            print(f"[discover-schema] phase=1 skip: {p1_out} exists (pass --force to rebuild)",
                  file=sys.stderr, flush=True)
            do_phase1 = False
    if not do_phase0 and not do_phase1:
        return 0

    t0 = time.time()
    conn = connect()
    cur = conn.cursor()

    raw_objects = list_schema_objects(cur, args.catalog, args.schema)
    print(f"[discover-schema] {args.catalog}.{args.schema} → {len(raw_objects)} objects",
          file=sys.stderr, flush=True)

    view_defs = fetch_view_definitions(cur, args.catalog, args.schema)

    # Load the global upstream wiki index (Phase 0 output) so we can flip
    # bronze tables with Tier 1 wikis into in-scope.
    upstream_wiki_index: dict = {}
    uwi_path = OBJ_OUT_ROOT / "_upstream_wiki_index.json"
    if uwi_path.is_file():
        try:
            uwi_payload = json.loads(uwi_path.read_text(encoding="utf-8"))
            upstream_wiki_index = uwi_payload.get("wikis") or {}
            n_bronze = sum(1 for v in upstream_wiki_index.values()
                           if v.get("wiki_kind") == "bronze_tier1")
            print(f"[discover-schema] loaded upstream wiki index: "
                  f"{len(upstream_wiki_index)} total ({n_bronze} bronze_tier1)",
                  file=sys.stderr, flush=True)
        except Exception as e:
            print(f"[discover-schema] WARN: failed to load upstream wiki index ({e})",
                  file=sys.stderr, flush=True)

    # ---------- PHASE 0: classify + write _schema_card.md ----------
    out_path = p0_out
    if do_phase0:
        classified: list[dict] = []
        for i, obj in enumerate(raw_objects, 1):
            name = obj["name"]
            ttype = obj["table_type"] or ""
            print(f"  [{i}/{len(raw_objects)}] {name} ({ttype})",
                  file=sys.stderr, flush=True)

            vdef = view_defs.get(name) if "VIEW" in ttype.upper() else None
            lineage_rows: list[dict] = []
            if "VIEW" not in ttype.upper():
                fq = fully_qualified(args.catalog, args.schema, name)
                lineage_rows = fetch_table_lineage_writers(
                    cur, f"{args.catalog}.{args.schema}.{name}", args.lineage_lookback_days
                )
            fqn = f"{args.catalog}.{args.schema}.{name}".lower()
            uwi_hit = upstream_wiki_index.get(fqn)
            writer = classify_writer(name, ttype, vdef, lineage_rows, upstream_wiki_hit=uwi_hit)

            obj_entry = {**obj, "writer": writer}
            if vdef:
                obj_entry["upstreams_hint"] = hint_upstreams_from_view_def(vdef)
            classified.append(obj_entry)

        md = render_schema_card(args.schema, args.catalog, classified, args.lineage_lookback_days)
        out_path.write_text(md, encoding="utf-8")
        wall = round(time.time() - t0, 1)
        n_in = sum(1 for o in classified if o["writer"].get("in_scope"))
        print(f"[discover-schema] wrote {out_path} ({out_path.stat().st_size:,} bytes; "
              f"{n_in}/{len(classified)} in-scope; {wall}s)", file=sys.stderr, flush=True)
        if not do_phase1:
            cur.close(); conn.close()
            return 0

    # ---------- PHASE 1: read existing card → emit uc_inventory.json ----------
    out_path = p1_out
    if not do_phase1:
        cur.close(); conn.close()
        return 0
    card_path = schema_root / "_schema_card.md"
    if not card_path.exists():
        print(f"[discover-schema] phase=1 requires {card_path} (run phase=0 first)",
              file=sys.stderr)
        cur.close(); conn.close()
        return 2

    # Parse frontmatter
    txt = card_path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.+?)\n---\n", txt, re.DOTALL)
    if not m:
        print(f"[discover-schema] phase=1 could not parse frontmatter in {card_path}",
              file=sys.stderr)
        cur.close(); conn.close()
        return 2

    try:
        import yaml  # type: ignore
        card = yaml.safe_load(m.group(1))
    except ImportError:
        print("[discover-schema] phase=1 needs PyYAML. pip install pyyaml.", file=sys.stderr)
        cur.close(); conn.close()
        return 2

    in_scope = [o for o in (card.get("objects") or []) if o.get("in_scope")]
    if args.objects:
        keep = set(args.objects)
        before = len(in_scope)
        in_scope = [o for o in in_scope if o["name"] in keep]
        print(f"[discover-schema] phase=1 --objects filter: {len(in_scope)}/{before}",
              file=sys.stderr, flush=True)
    print(f"[discover-schema] phase=1 in-scope objects: {len(in_scope)}",
          file=sys.stderr, flush=True)

    if args.no_samples:
        args.sample_rows = 0

    cols_map = fetch_columns(cur, args.catalog, args.schema,
                             [{"name": o["name"]} for o in in_scope])

    objects_out: list[dict] = []
    for i, obj in enumerate(in_scope, 1):
        name = obj["name"]
        ttype = obj["type"] or ""
        fq = fully_qualified(args.catalog, args.schema, name)
        print(f"  [{i}/{len(in_scope)}] {name} ({ttype})", file=sys.stderr, flush=True)

        cols = cols_map.get(name, [])
        deinfo = fetch_describe_extended(cur, fq)

        row_count = None
        if args.row_counts:
            row_count = fetch_row_count(cur, fq, ttype)

        sample_rows = None
        if args.sample_rows > 0:
            sample_rows = fetch_sample_rows(cur, fq, args.sample_rows)

        # Per-column samples derived from the row sample
        per_col: dict[str, list] = {}
        if sample_rows:
            for row in sample_rows:
                if not isinstance(row, dict):
                    continue
                for k, v in row.items():
                    if v is None:
                        continue
                    bucket = per_col.setdefault(k, [])
                    if v not in bucket and len(bucket) < args.sample_rows:
                        bucket.append(v)
        cols_out = [{**c, "samples": per_col.get(c["name"], [])} for c in cols]

        view_def = view_defs.get(name)

        objects_out.append({
            "name": name,
            "full_name": f"{args.catalog}.{args.schema}.{name}",
            "in_scope": True,
            "table_type": ttype,
            "writer": obj.get("writer") or {},
            "format": deinfo.get("format"),
            "location": deinfo.get("location"),
            "owner": deinfo.get("owner"),
            "created_at": deinfo.get("created_at"),
            "uc_comment": None,  # populated below if information_schema had a row-level comment
            "row_count": row_count,
            "column_count": len(cols),
            "view_definition": view_def,
            "columns": cols_out,
            "sample_rows": sample_rows,
            "describe_error": deinfo.get("describe_error"),
        })

    cur.close(); conn.close()

    tables_total = sum(1 for o in objects_out if "VIEW" not in (o["table_type"] or "").upper())
    views_total = len(objects_out) - tables_total
    columns_total = sum(o["column_count"] for o in objects_out)
    cols_with_comment = sum(1 for o in objects_out for c in o["columns"] if c.get("comment"))
    objs_with_comment = sum(1 for o in objects_out if o.get("uc_comment"))

    # If --objects was used and an existing inventory already covers others, merge.
    existing_objects: list[dict] = []
    if args.objects and out_path.exists():
        try:
            prev = json.loads(out_path.read_text(encoding="utf-8"))
            keep_names = {o["name"] for o in objects_out}
            existing_objects = [o for o in (prev.get("objects") or [])
                                if o["name"] not in keep_names]
        except Exception:
            existing_objects = []
    merged_objects = objects_out + existing_objects

    payload = {
        "schema": args.schema,
        "catalog": args.catalog,
        "framework": "uc-pipeline-doc",
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "objects": merged_objects,
        "stats": {
            "objects_total": len(merged_objects),
            "objects_refreshed_this_run": len(objects_out),
            "tables": tables_total,
            "views": views_total,
            "columns_total": columns_total,
            "columns_with_uc_comment": cols_with_comment,
            "objects_with_uc_comment": objs_with_comment,
            "wall_seconds": round(time.time() - t0, 1),
        },
    }
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[discover-schema] wrote {out_path} ({out_path.stat().st_size:,} bytes; "
          f"{len(objects_out)} objects, {columns_total} columns)",
          file=sys.stderr, flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
