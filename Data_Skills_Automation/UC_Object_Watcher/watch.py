#!/usr/bin/env python3
"""Unity Catalog Object + Pipeline Watcher -- diff -> document -> conditional push.

Detects new UC tables/views (and column-signature changes) in the in-scope
output/KPI schemas (never *_stg), then drives the uc-pipeline-doc pack to learn
HOW each object is built -- fetching the writer notebook/pipeline source from the
production workspace (5263962954799003) -- generates the wiki + lineage, deploys
ALTER COMMENTs, and conditionally pushes a skill/domain amendment when a NEW
durable concept emerges.

State:
  current   = system.information_schema (live) OR a --current JSON file.
  baseline  = Data_Skills_Automation/UC_Object_Watcher/state/snapshot.json

Dry-run (offline):
  python Data_Skills_Automation/UC_Object_Watcher/watch.py \
      --current Data_Skills_Automation/UC_Object_Watcher/fixtures/current_objects.json \
      --snapshot Data_Skills_Automation/UC_Object_Watcher/fixtures/_tmp_snapshot.json \
      --dry-run --no-notify --no-runlog \
      --manifest-out Data_Skills_Automation/UC_Object_Watcher/out/manifest.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.runner import WatchSpec, run_app

APP = "uc_object"
DEFAULT_SNAPSHOT = "Data_Skills_Automation/UC_Object_Watcher/state/snapshot.json"
PROD_WORKSPACE_ID = "5263962954799003"
CATALOG = "main"

# In-scope output/KPI schemas. *_stg is ALWAYS excluded regardless of this list.
DEFAULT_SCHEMAS = [
    "etoro_kpi_prep",
    "etoro_kpi",
    "de_output",
    "bi_output",
    "dealing_output",
]


def _column_fingerprint(columns: list[dict[str, Any]]) -> list[str]:
    return sorted(
        f"{c.get('column_name') or c.get('name')}:{(c.get('data_type') or c.get('type') or '').lower()}"
        for c in columns
    )


def _fetch_live(schemas: list[str]) -> dict[str, Any]:
    from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env

    in_list = ", ".join("'" + s.replace("'", "''") + "'" for s in schemas)
    sql = f"""
SELECT c.table_schema, c.table_name, t.table_type, c.column_name, c.data_type
FROM {CATALOG}.information_schema.columns c
JOIN {CATALOG}.information_schema.tables t
  ON c.table_catalog = t.table_catalog
 AND c.table_schema  = t.table_schema
 AND c.table_name    = t.table_name
WHERE c.table_catalog = '{CATALOG}'
  AND c.table_schema IN ({in_list})
  AND lower(c.table_schema) NOT RLIKE '.*_stg$'
ORDER BY c.table_schema, c.table_name, c.ordinal_position
""".strip()
    w = make_workspace_client()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=warehouse_id_from_env())
    idx = {name: i for i, name in enumerate(cols)}
    grouped: dict[str, dict[str, Any]] = {}
    for r in rows:
        schema = r[idx["table_schema"]]
        table = r[idx["table_name"]]
        ttype = r[idx["table_type"]]
        key = f"{CATALOG}.{schema}.{table}"
        rec = grouped.setdefault(
            key,
            {"catalog": CATALOG, "schema": schema, "table": table, "table_type": ttype, "columns": []},
        )
        rec["columns"].append({"column_name": r[idx["column_name"]], "data_type": r[idx["data_type"]]})
    return grouped


def _normalize_records(raw: Any) -> dict[str, Any]:
    objs = raw.get("objects") if isinstance(raw, dict) else raw
    out: dict[str, Any] = {}
    for o in objs or []:
        schema = o.get("schema")
        table = o.get("table")
        if not schema or not table:
            continue
        if str(schema).lower().endswith("_stg"):
            continue
        catalog = o.get("catalog", CATALOG)
        out[f"{catalog}.{schema}.{table}"] = {
            "catalog": catalog,
            "schema": schema,
            "table": table,
            "table_type": o.get("table_type", "TABLE"),
            "columns": o.get("columns", []),
        }
    return out


def fetch_current(current_override: str | None) -> dict[str, dict[str, Any]]:
    if current_override:
        raw = json.loads(Path(current_override).read_text(encoding="utf-8"))
        records = _normalize_records(raw)
    else:
        records = _fetch_live(DEFAULT_SCHEMAS)

    out: dict[str, dict[str, Any]] = {}
    for key, rec in records.items():
        fp = _column_fingerprint(rec.get("columns", []))
        out[key] = {
            "catalog": rec["catalog"],
            "schema": rec["schema"],
            "table": rec["table"],
            "table_type": rec.get("table_type", "TABLE"),
            "n_columns": len(fp),
            "column_fingerprint": fp,
        }
    return out


def make_work_item(key: str, record: dict[str, Any], change_kind: str) -> WorkItem:
    kind = "uc_new_object" if change_kind == "new" else "uc_changed_object"
    return WorkItem(
        id=f"{APP}:{kind}:{key}",
        kind=kind,
        title=key,
        payload={
            "catalog": record["catalog"],
            "schema": record["schema"],
            "table": record["table"],
            "table_type": record["table_type"],
            "n_columns": record["n_columns"],
        },
        source_ref=key,
    )


def build_prompt(item: WorkItem, ctx: RunContext) -> str:
    p = item.payload
    schema = p["schema"]
    stage_step = (
        "4) STAGING MODE: if there is a new durable concept, run /skills-ingest only; "
        "DO NOT run /skills-push. If the wiki already covers it, return done. "
        "Leave pr_url as null.\n"
        if ctx.staging
        else "4) If yes, run /skills-ingest for the amendment and, if the overlap gate "
        "passes, /skills-push. If the wiki already covers it, return done without a PR.\n"
    )
    return (
        "You are the autonomous Unity Catalog object + pipeline watcher.\n"
        f"A UC object was detected as {item.kind}.\n"
        f"- fqn: {item.source_ref}\n"
        f"- table_type: {p['table_type']}\n"
        f"- columns: {p['n_columns']}\n"
        f"- production workspace for writer source: {PROD_WORKSPACE_ID}\n\n"
        "Required flow (uc-pipeline-doc pack):\n"
        f"1) Run the uc-pipeline-doc phases for {schema} scoped to this object "
        "(tools/uc_pipelines/run_pipeline.py): UC discovery, source-code fetch "
        f"(writer notebook/pipeline from workspace {PROD_WORKSPACE_ID} via "
        "fetch_writer_source.py), upstream-wiki bridge, column lineage, then "
        "generate the wiki + lineage files. Honor GATE-lineage-contract.\n"
        "2) Deploy ALTER COMMENTs to UC for this object.\n"
        "3) Decide whether the object's build logic reveals a NEW durable concept "
        "(a new metric, transform, or domain) not already in knowledge/skills/ or "
        "the dwh-domain skills.\n"
        f"{stage_step}"
        "5) Return exactly one line:\n"
        'RESULT_JSON:{"status":"done|skipped|error","artifact_ref":"<wiki path/skill id or null>",'
        '"pr_url":"<url or null>","notes":"short reason"}\n'
    )


def simulate(item: WorkItem) -> ItemOutcome:
    p = item.payload
    wiki = f"knowledge/UC_generated/{p['schema']}/{'Views' if p['table_type']=='VIEW' else 'Tables'}/{p['table']}.md"
    return ItemOutcome(
        item_id=item.id,
        status="done",
        ok=True,
        artifact_ref=f"wiki:{wiki}",
        pr_url=None,
        notes=f"dry-run: would document {item.source_ref} ({p['n_columns']} cols) via uc-pipeline-doc; conditional skill PR",
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
