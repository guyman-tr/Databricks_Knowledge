#!/usr/bin/env python3
from __future__ import annotations

import datetime as dt
import json
import re
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.flow_catalog import FLOW_CATALOG, FlowDef
from tools.migration_autoloop.orchestration import SqlTaskSpec, create_or_update_sql_job

WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_autoloop"


def _yesterday_id() -> str:
    d = dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)
    return d.strftime("%Y%m%d")


def _job_name(flow: FlowDef) -> str:
    safe = re.sub(r"[^A-Za-z0-9_]+", "_", flow.flow_id)
    return f"DWH_Daily_Process__{safe}_AutoPOC"


def _run_sql(flow: FlowDef) -> str:
    if flow.has_date_param:
        return (
            f"CALL dwh_daily_process.migration_tables.{flow.procedure_name}("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        )
    return f"CALL dwh_daily_process.migration_tables.{flow.procedure_name}();\n"


def _qa_probe_sql(flow: FlowDef) -> str:
    if flow.date_slice_column and flow.compare_on_common_date:
        col = flow.date_slice_column
        return (
            "WITH bounds AS (\n"
            "  SELECT LEAST(\n"
            f"    (SELECT MAX(CAST({col} AS BIGINT)) FROM {flow.migration_table}),\n"
            f"    (SELECT MAX(CAST({col} AS BIGINT)) FROM {flow.gold_table})\n"
            "  ) AS common_date\n"
            ")\n"
            "SELECT\n"
            "  common_date,\n"
            f"  (SELECT COUNT(*) FROM {flow.migration_table} m WHERE CAST(m.{col} AS BIGINT) = common_date) AS migration_rows,\n"
            f"  (SELECT COUNT(*) FROM {flow.gold_table} g WHERE CAST(g.{col} AS BIGINT) = common_date) AS gold_rows\n"
            "FROM bounds;\n"
        )

    if flow.date_slice_column:
        col = flow.date_slice_column
        yid = _yesterday_id()
        return (
            "SELECT\n"
            f"  '{yid}' AS target_date_id,\n"
            f"  (SELECT COUNT(*) FROM {flow.migration_table} m WHERE LEFT(CAST(m.{col} AS STRING), 8) = '{yid}') AS migration_rows,\n"
            f"  (SELECT COUNT(*) FROM {flow.gold_table} g WHERE LEFT(CAST(g.{col} AS STRING), 8) = '{yid}') AS gold_rows;\n"
        )

    return (
        "SELECT\n"
        f"  (SELECT COUNT(*) FROM {flow.migration_table}) AS migration_rows,\n"
        f"  (SELECT COUNT(*) FROM {flow.gold_table}) AS gold_rows;\n"
    )


def _parity_gate_sql(flow: FlowDef) -> str:
    if flow.date_slice_column and flow.compare_on_common_date:
        col = flow.date_slice_column
        return (
            "WITH bounds AS (\n"
            "  SELECT LEAST(\n"
            f"    (SELECT MAX(CAST({col} AS BIGINT)) FROM {flow.migration_table}),\n"
            f"    (SELECT MAX(CAST({col} AS BIGINT)) FROM {flow.gold_table})\n"
            "  ) AS common_date\n"
            "), agg AS (\n"
            "  SELECT\n"
            "    common_date,\n"
            f"    (SELECT COUNT(*) FROM {flow.migration_table} m WHERE CAST(m.{col} AS BIGINT) = common_date) AS migration_rows,\n"
            f"    (SELECT COUNT(*) FROM {flow.gold_table} g WHERE CAST(g.{col} AS BIGINT) = common_date) AS gold_rows\n"
            "  FROM bounds\n"
            ")\n"
            "SELECT CASE\n"
            "  WHEN migration_rows = gold_rows THEN concat('PARITY_PASS common_date=', CAST(common_date AS STRING))\n"
            "  ELSE raise_error(\n"
            "    concat(\n"
            f"      'PARITY_FAIL {flow.flow_id} common_date=', CAST(common_date AS STRING),\n"
            "      ' migration_rows=', CAST(migration_rows AS STRING),\n"
            "      ' gold_rows=', CAST(gold_rows AS STRING)\n"
            "    )\n"
            "  )\n"
            "END AS parity_status\n"
            "FROM agg;\n"
        )

    if flow.date_slice_column:
        col = flow.date_slice_column
        yid = _yesterday_id()
        return (
            "WITH agg AS (\n"
            "  SELECT\n"
            f"    (SELECT COUNT(*) FROM {flow.migration_table} m WHERE LEFT(CAST(m.{col} AS STRING), 8) = '{yid}') AS migration_rows,\n"
            f"    (SELECT COUNT(*) FROM {flow.gold_table} g WHERE LEFT(CAST(g.{col} AS STRING), 8) = '{yid}') AS gold_rows\n"
            ")\n"
            "SELECT CASE\n"
            "  WHEN migration_rows = gold_rows THEN 'PARITY_PASS'\n"
            "  ELSE raise_error(\n"
            "    concat('PARITY_FAIL migration_rows=', CAST(migration_rows AS STRING), ' gold_rows=', CAST(gold_rows AS STRING))\n"
            "  )\n"
            "END AS parity_status\n"
            "FROM agg;\n"
        )

    return (
        "WITH agg AS (\n"
        "  SELECT\n"
        f"    (SELECT COUNT(*) FROM {flow.migration_table}) AS migration_rows,\n"
        f"    (SELECT COUNT(*) FROM {flow.gold_table}) AS gold_rows\n"
        ")\n"
        "SELECT CASE\n"
        "  WHEN migration_rows = gold_rows THEN 'PARITY_PASS'\n"
        "  ELSE raise_error(\n"
        "    concat('PARITY_FAIL migration_rows=', CAST(migration_rows AS STRING), ' gold_rows=', CAST(gold_rows AS STRING))\n"
        "  )\n"
        "END AS parity_status\n"
        "FROM agg;\n"
    )


def ensure_flow_job(flow_id: str) -> dict[str, object]:
    if flow_id not in FLOW_CATALOG:
        raise ValueError(f"Unknown flow_id: {flow_id}")
    flow = FLOW_CATALOG[flow_id]
    specs = [
        SqlTaskSpec(
            task_key="snapshot_guard",
            sql_filename=f"{flow_id}_01_snapshot_guard.sql",
            sql_text="SELECT current_date() AS run_date, DATEADD(DAY, -1, current_date()) AS target_date;\n",
        ),
        SqlTaskSpec(
            task_key="run_proc",
            sql_filename=f"{flow_id}_02_run_proc.sql",
            sql_text=_run_sql(flow),
            depends_on=("snapshot_guard",),
        ),
        SqlTaskSpec(
            task_key="qa_probe",
            sql_filename=f"{flow_id}_03_qa_probe.sql",
            sql_text=_qa_probe_sql(flow),
            depends_on=("run_proc",),
        ),
        SqlTaskSpec(
            task_key="parity_gate",
            sql_filename=f"{flow_id}_04_parity_gate.sql",
            sql_text=_parity_gate_sql(flow),
            depends_on=("qa_probe",),
        ),
    ]
    payload = create_or_update_sql_job(
        profile="guyman",
        job_name=_job_name(flow),
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        task_specs=specs,
    )
    payload["flow_id"] = flow_id
    return payload


def main() -> int:
    ap = __import__("argparse").ArgumentParser()
    ap.add_argument("--flow-id", required=True, choices=sorted(FLOW_CATALOG.keys()))
    args = ap.parse_args()
    payload = ensure_flow_job(args.flow_id)
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
