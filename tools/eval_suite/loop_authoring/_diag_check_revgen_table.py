"""Sanity-check whether the DDR revenue table exists for 2026-06-08.

Sends the exact same SQL we asked cursor-agent to run, but via the SDK
(known-good auth path used by our DirectSQLSUT).
"""
from __future__ import annotations
import time
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

WAREHOUSE_ID_ENV = "DATABRICKS_WAREHOUSE_ID"
import os

w = WorkspaceClient()
warehouse_id = os.environ.get(WAREHOUSE_ID_ENV)
if not warehouse_id:
    # Pick the first available warehouse
    for wh in w.warehouses.list():
        warehouse_id = wh.id
        print(f"Using warehouse: {wh.name} ({wh.id})")
        break

queries = [
    "SELECT COUNT(*) AS n FROM main.de_output.de_output_etoro_kpi_fact_revenue_generating_actions WHERE DateID = 20260608",
    "SELECT COUNT(*) AS n FROM main.de_output.de_output_etoro_kpi_fact_revenue_generating_actions",
    "SHOW TABLES IN main.de_output LIKE 'de_output_etoro_kpi_fact_revenue_generating_actions*'",
]

for q in queries:
    print(f"\n>>> {q}")
    resp = w.statement_execution.execute_statement(
        statement=q, warehouse_id=warehouse_id, wait_timeout="30s"
    )
    sid = resp.statement_id
    while True:
        s = w.statement_execution.get_statement(sid)
        if s.status.state in (StatementState.SUCCEEDED, StatementState.FAILED, StatementState.CANCELED):
            break
        time.sleep(0.5)
    if s.status.state == StatementState.SUCCEEDED:
        rows = s.result.data_array if s.result else []
        print(f"OK -> {rows[:5]}")
    else:
        print(f"FAILED -> {s.status.error.message if s.status.error else s.status.state}")
