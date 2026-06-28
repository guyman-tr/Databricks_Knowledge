#!/usr/bin/env python3
"""DB-Schema Lake Wiki Watcher -- diff -> cross-ref lake -> conditional push.

Detects new / changed Synapse source-DB table wikis (in the DB_Schema repo:
etoro, banking, crypto, compliance, ...) that ALSO map to a lake/UC object via
the Generic Pipeline. For each such lake-backed table wiki, ingests the semantic
knowledge and conditionally pushes a skill/domain amendment linking the Synapse
source table to its bronze UC object.

A table is in scope only if (database_name, schema_name, table_name) intersects
knowledge/synapse/Wiki/_generic_pipeline_mapping.json -- i.e. the Generic
Pipeline materializes it to the lake.

State:
  current   = DB_Schema repo wikis intersected with the generic mapping (live),
              OR a --current JSON file.
  baseline  = Data_Skills_Automation/DBSchema_Lake_Watcher/state/snapshot.json

Dry-run (offline):
  python Data_Skills_Automation/DBSchema_Lake_Watcher/watch.py \
      --current Data_Skills_Automation/DBSchema_Lake_Watcher/fixtures/current_wikis.json \
      --snapshot Data_Skills_Automation/DBSchema_Lake_Watcher/fixtures/_tmp_snapshot.json \
      --dry-run --no-notify --no-runlog \
      --manifest-out Data_Skills_Automation/DBSchema_Lake_Watcher/out/manifest.json
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.runner import WatchSpec, run_app

APP = "dbschema"
DEFAULT_SNAPSHOT = "Data_Skills_Automation/DBSchema_Lake_Watcher/state/snapshot.json"
MAPPING_PATH = REPO_ROOT / "knowledge" / "synapse" / "Wiki" / "_generic_pipeline_mapping.json"
DB_SCHEMA_REPO = REPO_ROOT.parent / "DB_Schema"
# Only table wikis can be lake-backed by the Generic Pipeline.
OBJECT_TYPE_DIR = "Tables"


def _load_mapping_index() -> dict[tuple[str, str, str], dict[str, str]]:
    if not MAPPING_PATH.exists():
        raise SystemExit(f"generic pipeline mapping not found: {MAPPING_PATH}")
    data = json.loads(MAPPING_PATH.read_text(encoding="utf-8"))
    index: dict[tuple[str, str, str], dict[str, str]] = {}
    for m in data.get("mappings", []):
        key = (
            str(m.get("database_name", "")).lower(),
            str(m.get("schema_name", "")).lower(),
            str(m.get("table_name", "")).lower(),
        )
        index[key] = {
            "uc_table": m.get("uc_table", ""),
            "business_group": m.get("business_group", ""),
            "datalake_path": m.get("datalake_path", ""),
        }
    return index


def _parse_wiki_path(db: str, wiki_root: Path, md: Path) -> tuple[str, str, str] | None:
    """Return (schema, object_type, object) from {DB}/Wiki/{Schema}/{Type}/{file}.md."""
    rel = md.relative_to(wiki_root)
    parts = rel.parts
    if len(parts) < 3:
        return None
    schema, object_type, fname = parts[0], parts[1], parts[-1]
    if fname.startswith("_"):
        return None
    stem = fname[:-3] if fname.endswith(".md") else fname
    prefix = f"{schema}."
    obj = stem[len(prefix):] if stem.startswith(prefix) else stem
    return schema, object_type, obj


def _fetch_live() -> dict[str, Any]:
    mapping = _load_mapping_index()
    if not DB_SCHEMA_REPO.exists():
        raise SystemExit(f"DB_Schema repo not found at {DB_SCHEMA_REPO}; pass --current instead.")

    records: dict[str, Any] = {}
    for db_dir in DB_SCHEMA_REPO.iterdir():
        if not db_dir.is_dir() or db_dir.name.startswith("."):
            continue
        wiki_root = db_dir / "Wiki"
        if not wiki_root.exists():
            continue
        db = db_dir.name
        for md in wiki_root.rglob(f"*/{OBJECT_TYPE_DIR}/*.md"):
            parsed = _parse_wiki_path(db, wiki_root, md)
            if not parsed:
                continue
            schema, object_type, obj = parsed
            hit = mapping.get((db.lower(), schema.lower(), obj.lower()))
            if not hit:
                continue  # not lake-backed -> out of scope
            content = md.read_text(encoding="utf-8", errors="replace")
            key = f"{db}.{schema}.{obj}"
            records[key] = {
                "db": db,
                "schema": schema,
                "object": obj,
                "object_type": object_type,
                "wiki_path": str(md.relative_to(REPO_ROOT.parent)).replace("\\", "/"),
                "uc_table": hit["uc_table"],
                "business_group": hit["business_group"],
                "wiki_sha": hashlib.sha256(content.encode("utf-8")).hexdigest(),
            }
    return records


def _normalize_records(raw: Any) -> dict[str, Any]:
    wikis = raw.get("wikis") if isinstance(raw, dict) else raw
    mapping: dict[tuple[str, str, str], dict[str, str]] | None = None
    out: dict[str, Any] = {}
    for w in wikis or []:
        db, schema, obj = w.get("db"), w.get("schema"), w.get("object")
        if not (db and schema and obj):
            continue
        if (w.get("object_type") or OBJECT_TYPE_DIR) != OBJECT_TYPE_DIR:
            continue
        uc_table = w.get("uc_table")
        business_group = w.get("business_group", "")
        if not uc_table:
            # Resolve from the real mapping so fixtures can test intersection.
            if mapping is None:
                mapping = _load_mapping_index()
            hit = mapping.get((db.lower(), schema.lower(), obj.lower()))
            if not hit:
                continue
            uc_table = hit["uc_table"]
            business_group = hit["business_group"]
        content = w.get("content")
        sha = w.get("wiki_sha") or (
            hashlib.sha256(content.encode("utf-8")).hexdigest() if content else "fixture-sha"
        )
        out[f"{db}.{schema}.{obj}"] = {
            "db": db,
            "schema": schema,
            "object": obj,
            "object_type": OBJECT_TYPE_DIR,
            "wiki_path": w.get("wiki_path", ""),
            "uc_table": uc_table,
            "business_group": business_group,
            "wiki_sha": sha,
        }
    return out


def fetch_current(current_override: str | None) -> dict[str, dict[str, Any]]:
    if current_override:
        raw = json.loads(Path(current_override).read_text(encoding="utf-8"))
        return _normalize_records(raw)
    return _fetch_live()


def make_work_item(key: str, record: dict[str, Any], change_kind: str) -> WorkItem:
    kind = "dbschema_new_wiki" if change_kind == "new" else "dbschema_changed_wiki"
    return WorkItem(
        id=f"{APP}:{kind}:{key}",
        kind=kind,
        title=f"{key} -> {record['uc_table']}",
        payload={
            "db": record["db"],
            "schema": record["schema"],
            "object": record["object"],
            "wiki_path": record["wiki_path"],
            "uc_table": record["uc_table"],
            "business_group": record["business_group"],
        },
        source_ref=key,
    )


def build_prompt(item: WorkItem, ctx: RunContext) -> str:
    p = item.payload
    stage_step = (
        "4) STAGING MODE: if there is new durable knowledge, run /skills-ingest only; "
        "DO NOT run /skills-push. Otherwise return skipped.\n"
        if ctx.staging
        else "4) If yes, run /skills-ingest for the amendment and, if the overlap gate "
        "passes, /skills-push. Otherwise return skipped.\n"
    )
    return (
        "You are the autonomous DB-Schema lake wiki watcher.\n"
        f"A lake-backed Synapse source table wiki was detected as {item.kind}.\n"
        f"- source table: {item.source_ref}\n"
        f"- wiki: {p['wiki_path']}\n"
        f"- lake/UC object (Generic Pipeline): {p['uc_table']}\n"
        f"- business_group: {p['business_group']}\n\n"
        "Required flow:\n"
        "1) Read the DB-Schema wiki for this table (semantic meaning, keys, enums, "
        "FK/lookup notes).\n"
        f"2) Cross-reference its lake/UC bronze object {p['uc_table']} (the Generic "
        "Pipeline target).\n"
        "3) Decide whether this introduces NEW durable knowledge linking the Synapse "
        "source to its lake object, or a metric/domain not already in "
        "knowledge/skills/ or the dwh-domain skills.\n"
        f"{stage_step}"
        "5) Return exactly one line:\n"
        'RESULT_JSON:{"status":"done|skipped|error","artifact_ref":"<skill id/domain or null>",'
        '"pr_url":"<url or null>","notes":"short reason"}\n'
    )


def simulate(item: WorkItem) -> ItemOutcome:
    p = item.payload
    return ItemOutcome(
        item_id=item.id,
        status="done",
        ok=True,
        artifact_ref=f"lake:{p['uc_table']}",
        pr_url=None,
        notes=f"dry-run: would ingest {item.source_ref} linked to {p['uc_table']} "
        f"(bg={p['business_group']}); conditional skill PR",
    )


SPEC = WatchSpec(
    app=APP,
    default_snapshot=DEFAULT_SNAPSHOT,
    fetch_current=fetch_current,
    make_work_item=make_work_item,
    build_prompt=build_prompt,
    simulate=simulate,
    model_role="ingest",
)


if __name__ == "__main__":
    sys.exit(run_app(SPEC))
