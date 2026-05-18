#!/usr/bin/env python3
"""
Phase 2 — Source Code Fetch (UC-Pipeline pack).

For each in-scope object in a schema's _schema_card.md:

  - VIEW  → write `_discovery/source_code/{Object}.sql` from the inlined
            view_definition captured by Phase 1.

  - TABLE → query system.access.table_lineage to resolve the writer
            (notebook / job / pipeline / UC function), export the source via
            the Databricks Workspace API, and snapshot it to
            `_discovery/source_code/{Object}.{py,sql}`.

  - Always → cache system.access.column_lineage for the object to
            `_discovery/column_lineage/{Object}.json` (Phase 4 cross-check).

Auth: same path as tools/uc_pipelines/discover_schema.py.

Usage:
  python tools/uc_pipelines/fetch_writer_source.py --schema etoro_kpi_prep
  python tools/uc_pipelines/fetch_writer_source.py --schema de_output --objects de_output_etoro_kpi_fact_customeraction_w_metrics
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

from uc_pipelines._conn import connect, workspace_client  # noqa: E402


OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"


def _load_yaml(path: Path) -> dict:
    txt = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.+?)\n---\n", txt, re.DOTALL)
    if not m:
        raise RuntimeError(f"no YAML frontmatter in {path}")
    try:
        import yaml  # type: ignore
        return yaml.safe_load(m.group(1))
    except ImportError:
        print("[fetch-writer] requires PyYAML. pip install pyyaml.", file=sys.stderr)
        raise


def _load_inventory(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _view_def_header(full_name: str) -> str:
    ts = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    return (f"-- ==========================================================================\n"
            f"-- Source: information_schema.views.view_definition\n"
            f"-- Object: {full_name}\n"
            f"-- Captured: {ts}\n"
            f"-- ==========================================================================\n\n")


def _notebook_header(full_name: str, writer_path: str, language: str, source_url: str | None) -> str:
    ts = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    src = source_url or writer_path
    return (f"# ==========================================================================\n"
            f"# Source: system.access.table_lineage → Workspace API export\n"
            f"# Object:  {full_name}\n"
            f"# Writer:  {writer_path}\n"
            f"# Language: {language}\n"
            f"# Captured: {ts}\n"
            f"# Source URL: {src}\n"
            f"# ==========================================================================\n\n")


def fetch_view_def(view_definition: str | None) -> str | None:
    if not view_definition:
        return None
    return view_definition.strip()


# ---------- table_lineage / column_lineage ----------

def fetch_table_lineage(cur, full_name: str, lookback_days: int) -> list[dict]:
    sql = f"""
    SELECT
      entity_type, entity_id,
      source_table_full_name, source_type,
      COUNT(*) AS event_count,
      MIN(event_time) AS first_event_time,
      MAX(event_time) AS last_event_time
    FROM system.access.table_lineage
    WHERE lower(target_table_full_name) = lower('{full_name}')
      AND event_time > current_date - INTERVAL {lookback_days} DAYS
      AND entity_type IS NOT NULL
    GROUP BY entity_type, entity_id, source_table_full_name, source_type
    ORDER BY event_count DESC
    """
    try:
        cur.execute(sql)
    except Exception as e:
        print(f"[fetch-writer] table_lineage query failed for {full_name}: {e}", file=sys.stderr)
        return []
    return [{
        "entity_type": r[0],
        "entity_id": r[1],
        "source_table_full_name": r[2],
        "source_type": r[3],
        "event_count": int(r[4]) if r[4] is not None else 0,
        "first_event_time": r[5].isoformat() if hasattr(r[5], "isoformat") else r[5],
        "last_event_time": r[6].isoformat() if hasattr(r[6], "isoformat") else r[6],
    } for r in cur.fetchall()]


def fetch_column_lineage(cur, full_name: str, lookback_days: int) -> list[dict]:
    sql = f"""
    SELECT
      source_table_full_name, source_column_name, target_column_name,
      entity_type, COUNT(*) AS event_count
    FROM system.access.column_lineage
    WHERE lower(target_table_full_name) = lower('{full_name}')
      AND event_time > current_date - INTERVAL {lookback_days} DAYS
    GROUP BY source_table_full_name, source_column_name, target_column_name, entity_type
    ORDER BY target_column_name, event_count DESC
    """
    try:
        cur.execute(sql)
    except Exception as e:
        print(f"[fetch-writer] column_lineage query failed for {full_name}: {e}", file=sys.stderr)
        return []
    return [{
        "source_table_full_name": r[0],
        "source_column_name": r[1],
        "target_column_name": r[2],
        "entity_type": r[3],
        "event_count": int(r[4]) if r[4] is not None else 0,
    } for r in cur.fetchall()]


# ---------- writer source export ----------

def _unique_producers(lineage: list[dict]) -> list[dict]:
    """Collapse (entity_type, entity_id) pairs, summing event_count."""
    bucket: dict[tuple, dict] = {}
    for row in lineage:
        key = (row["entity_type"], row["entity_id"])
        if key not in bucket:
            bucket[key] = {
                "entity_type": row["entity_type"],
                "entity_id": row["entity_id"],
                "event_count": 0,
            }
        bucket[key]["event_count"] += row["event_count"]
    return sorted(bucket.values(), key=lambda r: -r["event_count"])


def export_notebook(ws, path: str) -> tuple[str, str] | None:
    """Return (language, body_text) for a workspace notebook path. None on failure."""
    try:
        meta = ws.workspace.get_status(path)
    except Exception as e:
        print(f"[fetch-writer] workspace.get_status failed for {path}: {e}", file=sys.stderr)
        return None
    if meta.object_type and str(meta.object_type).endswith("NOTEBOOK"):
        try:
            from databricks.sdk.service.workspace import ExportFormat
            resp = ws.workspace.export(path, format=ExportFormat.SOURCE)
        except Exception as e:
            print(f"[fetch-writer] workspace.export failed for {path}: {e}", file=sys.stderr)
            return None
        import base64
        body = base64.b64decode(resp.content).decode("utf-8", errors="replace")
        lang = (meta.language.value if meta.language else "PYTHON")
        return lang, body
    if meta.object_type and str(meta.object_type).endswith("FILE"):
        try:
            from databricks.sdk.service.workspace import ExportFormat
            resp = ws.workspace.export(path, format=ExportFormat.SOURCE)
            import base64
            body = base64.b64decode(resp.content).decode("utf-8", errors="replace")
            ext = path.lower().rsplit(".", 1)[-1] if "." in path else ""
            lang_map = {"py": "PYTHON", "sql": "SQL", "scala": "SCALA", "r": "R"}
            return lang_map.get(ext, "PYTHON"), body
        except Exception as e:
            print(f"[fetch-writer] workspace.export (FILE) failed for {path}: {e}", file=sys.stderr)
            return None
    print(f"[fetch-writer] {path} is not a NOTEBOOK or FILE (object_type={meta.object_type})", file=sys.stderr)
    return None


def fetch_job_notebooks(ws, job_id: str) -> list[tuple[str, str]]:
    """For a job id, return list of (task_name, notebook_path) for notebook tasks."""
    try:
        job = ws.jobs.get(int(job_id))
    except Exception as e:
        print(f"[fetch-writer] jobs.get({job_id}) failed: {e}", file=sys.stderr)
        return []
    paths: list[tuple[str, str]] = []
    tasks = (getattr(job.settings, "tasks", None) or [])
    for t in tasks:
        nt = getattr(t, "notebook_task", None)
        if nt and getattr(nt, "notebook_path", None):
            paths.append((getattr(t, "task_key", "task"), nt.notebook_path))
    return paths


def fetch_pipeline_notebooks(ws, pipeline_id: str) -> list[str]:
    """For a DLT pipeline id, return list of source notebook paths."""
    try:
        pipe = ws.pipelines.get(pipeline_id)
    except Exception as e:
        print(f"[fetch-writer] pipelines.get({pipeline_id}) failed: {e}", file=sys.stderr)
        return []
    libs = getattr(pipe.spec, "libraries", None) or []
    out = []
    for lib in libs:
        nb = getattr(lib, "notebook", None)
        if nb and getattr(nb, "path", None):
            out.append(nb.path)
    return out


def fetch_uc_function_body(cur, full_name: str) -> str | None:
    try:
        cur.execute(f"SHOW CREATE FUNCTION {full_name}")
        rows = cur.fetchall()
        if not rows:
            return None
        return rows[0][0] if rows[0][0] else None
    except Exception as e:
        print(f"[fetch-writer] SHOW CREATE FUNCTION failed for {full_name}: {e}", file=sys.stderr)
        return None


# ---------- main per-object pipeline ----------

def write_view_snapshot(out_root: Path, name: str, view_def: str, full_name: str) -> Path:
    p = out_root / "source_code" / f"{name}.sql"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(_view_def_header(full_name) + view_def + "\n", encoding="utf-8")
    return p


def write_notebook_snapshot(out_root: Path, name: str, full_name: str,
                            blocks: list[tuple[str, str, str]]) -> Path:
    """Write concatenated notebook snapshot. blocks = [(role, writer_path, body)]."""
    primary_lang = "PYTHON"
    if blocks:
        # Use the most common language as the file extension
        from collections import Counter
        primary_lang = Counter([b[0].split("|")[0] for b in blocks]).most_common(1)[0][0]
    ext = {"PYTHON": "py", "SQL": "sql", "SCALA": "scala", "R": "r"}.get(primary_lang, "py")
    p = out_root / "source_code" / f"{name}.{ext}"
    p.parent.mkdir(parents=True, exist_ok=True)

    parts: list[str] = []
    for i, (lang_tag, writer_path, body) in enumerate(blocks, 1):
        lang, role = (lang_tag.split("|", 1) + [""])[:2]
        parts.append(_notebook_header(full_name, writer_path, lang,
                                       source_url=f"databricks://workspace{writer_path}"))
        if role:
            parts.append(f"# >>>>> writer #{i} role={role}\n")
        parts.append(body.rstrip())
        parts.append("\n\n")
    p.write_text("".join(parts), encoding="utf-8")
    return p


def write_writers_manifest(out_root: Path, name: str, full_name: str,
                           writers: list[dict]) -> Path:
    p = out_root / "source_code" / "_writers" / f"{name}.json"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({
        "object": full_name,
        "writers": writers,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    return p


def write_column_lineage_cache(out_root: Path, name: str, full_name: str,
                                rows: list[dict]) -> Path:
    p = out_root / "column_lineage" / f"{name}.json"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({
        "object": full_name,
        "rows": rows,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    return p


def fetch_one_object(cur, ws, obj: dict, lookback_days: int, out_root: Path) -> dict:
    """Returns a per-object summary dict."""
    name = obj["name"]
    full = obj["full_name"]
    ttype = (obj["table_type"] or "").upper()
    summary: dict = {"object": full, "name": name, "table_type": ttype}

    # column_lineage cache (always)
    clrows = fetch_column_lineage(cur, full, lookback_days)
    summary["column_lineage_cache"] = str(write_column_lineage_cache(out_root, name, full, clrows).relative_to(REPO))
    summary["column_lineage_row_count"] = len(clrows)

    if "VIEW" in ttype:
        vdef = fetch_view_def(obj.get("view_definition"))
        if not vdef:
            summary["status"] = "NO_VIEW_DEFINITION"
            return summary
        path = write_view_snapshot(out_root, name, vdef, full)
        summary["status"] = "OK"
        summary["source_code"] = str(path.relative_to(REPO))
        summary["writers"] = [{"kind": "view_definition", "role": "primary"}]
        return summary

    # TABLE / MATERIALIZED_VIEW
    lineage = fetch_table_lineage(cur, full, lookback_days)
    producers = _unique_producers(lineage)

    if not producers:
        summary["status"] = "NO_LINEAGE"
        summary["writers"] = []
        return summary

    # Walk producers, fetch source
    writers_out: list[dict] = []
    blocks: list[tuple[str, str, str]] = []
    primary_kind = None

    for i, prod in enumerate(producers[:5]):  # cap at 5 writers
        et = (prod["entity_type"] or "").upper()
        eid = prod["entity_id"]
        role = "primary" if i == 0 else "secondary"

        entry = {
            "kind": et,
            "entity_id": eid,
            "event_count_lookback": prod["event_count"],
            "role": role,
        }

        if et == "NOTEBOOK":
            res = export_notebook(ws, eid)
            if res:
                lang, body = res
                blocks.append((f"{lang}|{role}", eid, body))
                entry["path"] = eid
                entry["language"] = lang
                entry["fetched"] = True
            else:
                entry["fetched"] = False
                entry["fetch_error"] = "workspace.export failed"
        elif et == "JOB":
            paths = fetch_job_notebooks(ws, eid)
            if not paths:
                entry["fetched"] = False
                entry["fetch_error"] = "job has no notebook tasks"
            else:
                entry["notebooks"] = []
                for task_key, p in paths:
                    res = export_notebook(ws, p)
                    if res:
                        lang, body = res
                        blocks.append((f"{lang}|{role} job={eid} task={task_key}", p, body))
                        entry["notebooks"].append({"task": task_key, "path": p, "language": lang, "fetched": True})
                    else:
                        entry["notebooks"].append({"task": task_key, "path": p, "fetched": False})
                entry["fetched"] = any(n["fetched"] for n in entry["notebooks"])
        elif et == "PIPELINE":
            paths = fetch_pipeline_notebooks(ws, eid)
            if not paths:
                entry["fetched"] = False
                entry["fetch_error"] = "pipeline has no notebook libraries"
            else:
                entry["notebooks"] = []
                for p in paths:
                    res = export_notebook(ws, p)
                    if res:
                        lang, body = res
                        blocks.append((f"{lang}|{role} pipeline={eid}", p, body))
                        entry["notebooks"].append({"path": p, "language": lang, "fetched": True})
                    else:
                        entry["notebooks"].append({"path": p, "fetched": False})
                entry["fetched"] = any(n["fetched"] for n in entry["notebooks"])
        elif et == "UC_FUNCTION":
            body = fetch_uc_function_body(cur, eid)
            if body:
                blocks.append((f"SQL|{role} uc_function={eid}", eid, body))
                entry["fetched"] = True
            else:
                entry["fetched"] = False
        elif et == "QUERY":
            entry["fetched"] = False
            entry["fetch_error"] = "QUERY entity — ad-hoc SQL editor, not exportable"
        else:
            entry["fetched"] = False
            entry["fetch_error"] = f"unrecognised entity_type={et}"

        writers_out.append(entry)
        if primary_kind is None:
            primary_kind = et

    summary["writers"] = writers_out
    summary["writers_manifest"] = str(write_writers_manifest(out_root, name, full, writers_out).relative_to(REPO))

    if blocks:
        path = write_notebook_snapshot(out_root, name, full, blocks)
        summary["source_code"] = str(path.relative_to(REPO))
        summary["status"] = "OK"
    else:
        summary["status"] = "WRITER_FOUND_BUT_NO_SOURCE_FETCHED"

    return summary


# ============================== main ==============================

def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline source-code fetch (Phase 2)")
    ap.add_argument("--schema", required=True, help="UC schema name (e.g. etoro_kpi_prep)")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--objects", nargs="+", default=None,
                    help="Optional: subset of object names to (re-)fetch")
    ap.add_argument("--lineage-lookback-days", type=int, default=90)
    ap.add_argument("--no-workspace", action="store_true",
                    help="Skip Workspace API (only handles VIEW + column_lineage cache).")
    ap.add_argument("--out-root", default=None,
                    help="Override _discovery root. Default: knowledge/UC_generated/{schema}/_discovery")
    ap.add_argument("--force", action="store_true",
                    help="Re-fetch sources even if cached")
    args = ap.parse_args()

    schema_root = OBJ_OUT_ROOT / args.schema
    if not schema_root.exists():
        print(f"[fetch-writer] schema folder not found: {schema_root}. "
              f"Run discover_schema.py --schema {args.schema} first.", file=sys.stderr)
        return 2
    inv_path = schema_root / "_discovery" / "uc_inventory.json"
    if not inv_path.exists():
        print(f"[fetch-writer] inventory not found: {inv_path}. "
              f"Run discover_schema.py --schema {args.schema} --phase 1 first.", file=sys.stderr)
        return 2

    out_root = Path(args.out_root) if args.out_root else (schema_root / "_discovery")
    out_root.mkdir(parents=True, exist_ok=True)

    inv = _load_inventory(inv_path)
    target_objects = inv.get("objects", [])
    if args.objects:
        keep = set(args.objects)
        target_objects = [o for o in target_objects if o["name"] in keep]
    if not target_objects:
        print("[fetch-writer] no target objects.", file=sys.stderr)
        return 1

    print(f"[fetch-writer] {args.catalog}.{args.schema} → {len(target_objects)} objects "
          f"(lookback={args.lineage_lookback_days}d)", file=sys.stderr, flush=True)

    t0 = time.time()
    conn = connect()
    cur = conn.cursor()

    # Lazy WS client — only needed for non-VIEW objects
    needs_ws = (not args.no_workspace) and any(
        "VIEW" not in (o["table_type"] or "").upper() for o in target_objects
    )
    ws = None
    if needs_ws:
        try:
            ws = workspace_client()
        except Exception as e:
            print(f"[fetch-writer] WARN: workspace_client failed ({e}); will skip notebook export",
                  file=sys.stderr)
            ws = None

    summaries: list[dict] = []
    for i, obj in enumerate(target_objects, 1):
        print(f"  [{i}/{len(target_objects)}] {obj['name']} ({obj['table_type']})",
              file=sys.stderr, flush=True)
        # Bronze tables with Tier 1 inheritance have no UC writer of their own
        # (the producer is the generic ingest pipeline, owned upstream). Skip
        # Phase 2 fetch — generate_wiki handles them via pure inheritance.
        writer_kind = ((obj.get("writer") or {}).get("kind") or "").upper()
        if writer_kind == "BRONZE_TIER1_INHERITANCE":
            summaries.append({
                "object": obj["full_name"], "name": obj["name"],
                "status": "BRONZE_TIER1_NO_WRITER_TO_FETCH",
                "note": "bronze passthrough — sourced from Tier 1 production wiki, no UC writer",
            })
            continue
        try:
            s = fetch_one_object(cur, ws, obj, args.lineage_lookback_days, out_root)
        except Exception as e:
            s = {"object": obj["full_name"], "name": obj["name"], "status": "ERROR", "error": str(e)[:300]}
            print(f"    ERROR: {e}", file=sys.stderr)
        summaries.append(s)

    cur.close(); conn.close()

    # Manifest
    manifest = {
        "schema": args.schema,
        "catalog": args.catalog,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "lineage_lookback_days": args.lineage_lookback_days,
        "objects": summaries,
        "stats": {
            "ok": sum(1 for s in summaries if s.get("status") == "OK"),
            "no_lineage": sum(1 for s in summaries if s.get("status") == "NO_LINEAGE"),
            "no_view_def": sum(1 for s in summaries if s.get("status") == "NO_VIEW_DEFINITION"),
            "errors": sum(1 for s in summaries if s.get("status") == "ERROR"),
            "wall_seconds": round(time.time() - t0, 1),
        },
    }
    manifest_path = out_root / "source_code" / "_fetch_manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[fetch-writer] wrote {manifest_path} (ok={manifest['stats']['ok']}, "
          f"no_lineage={manifest['stats']['no_lineage']}, errors={manifest['stats']['errors']})",
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
