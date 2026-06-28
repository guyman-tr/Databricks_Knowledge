"""Per-app run-log writer for the auto_kb framework.

Each app writes one row per processed item into an EXTERNAL Delta table in
main.de_output. Table names are purge-formula compliant (see naming.py): the
location path segments under the analysis container join to the table name.

    DE_OUTPUT/Auto_Kb/Genie_Runs/      -> de_output_auto_kb_genie_runs
    DE_OUTPUT/Auto_Kb/Uc_Object_Runs/  -> de_output_auto_kb_uc_object_runs
    DE_OUTPUT/Auto_Kb/Dbschema_Runs/   -> de_output_auto_kb_dbschema_runs
    DE_OUTPUT/Auto_Kb/Confluence_Runs/ -> de_output_auto_kb_confluence_runs
    DE_OUTPUT/Auto_Kb/Questions_Runs/  -> de_output_auto_kb_questions_runs
"""
from __future__ import annotations

import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.skill_suggestions.naming import validate_table_name_and_location
from tools.auto_kb.models import ItemOutcome, WorkItem

SCHEMA = "de_output"
CATALOG = "main"
_ABFSS_PREFIX = "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net"

# app -> (table_name, location)
RUN_LOG_SPECS: dict[str, tuple[str, str]] = {
    "genie": (
        "de_output_auto_kb_genie_runs",
        f"{_ABFSS_PREFIX}/DE_OUTPUT/Auto_Kb/Genie_Runs/",
    ),
    "uc_object": (
        "de_output_auto_kb_uc_object_runs",
        f"{_ABFSS_PREFIX}/DE_OUTPUT/Auto_Kb/Uc_Object_Runs/",
    ),
    "dbschema": (
        "de_output_auto_kb_dbschema_runs",
        f"{_ABFSS_PREFIX}/DE_OUTPUT/Auto_Kb/Dbschema_Runs/",
    ),
    "confluence": (
        "de_output_auto_kb_confluence_runs",
        f"{_ABFSS_PREFIX}/DE_OUTPUT/Auto_Kb/Confluence_Runs/",
    ),
    "questions": (
        "de_output_auto_kb_questions_runs",
        f"{_ABFSS_PREFIX}/DE_OUTPUT/Auto_Kb/Questions_Runs/",
    ),
}


def table_fqn(app: str) -> str:
    name, _ = RUN_LOG_SPECS[app]
    return f"{CATALOG}.{SCHEMA}.{name}"


def assert_naming_compliant(app: str) -> None:
    """Fail fast if the run-log table would be dropped by the purger."""
    name, location = RUN_LOG_SPECS[app]
    result = validate_table_name_and_location(
        schema=SCHEMA, table_name=name, location=location
    )
    if not result.is_valid:
        raise RuntimeError(
            f"run-log table for app={app} is NOT purge-compliant: "
            f"expected_name={result.expected_table_name} got={name} "
            f"env_ok={result.env_ok} schema_ok={result.schema_ok} "
            f"is_abfss={result.is_abfss}"
        )


def _sql_quote(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def record_outcome(
    *,
    app: str,
    run_id: str,
    item: WorkItem,
    outcome: ItemOutcome,
    dry_run: bool,
    skip: bool,
) -> None:
    if dry_run or skip:
        print(
            f"[no-runlog] app={app} run={run_id} item={outcome.item_id} "
            f"status={outcome.status} pr={outcome.pr_url}"
        )
        return

    assert_naming_compliant(app)
    sql = f"""
INSERT INTO {table_fqn(app)} (
  run_id, app, item_id, item_kind, title, detected_at,
  status, artifact_ref, pr_url, notes, processed_at
) VALUES (
  {_sql_quote(run_id)},
  {_sql_quote(app)},
  {_sql_quote(outcome.item_id)},
  {_sql_quote(item.kind)},
  {_sql_quote(item.title)},
  current_timestamp(),
  {_sql_quote(outcome.status)},
  {_sql_quote(outcome.artifact_ref)},
  {_sql_quote(outcome.pr_url)},
  {_sql_quote(outcome.notes)},
  current_timestamp()
)
""".strip()
    w = make_workspace_client()
    execute_sql(w, sql_text=sql, warehouse_id=warehouse_id_from_env())
