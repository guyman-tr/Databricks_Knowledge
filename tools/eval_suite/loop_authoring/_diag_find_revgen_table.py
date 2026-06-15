"""Locate the actual DDR revenue-generating-actions table in UC."""
from __future__ import annotations
import time, os
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

w = WorkspaceClient()
warehouse_id = os.environ.get("DATABRICKS_WAREHOUSE_ID")
if not warehouse_id:
    warehouse_id = next(w.warehouses.list()).id

def run(q: str, label: str):
    print(f"\n>>> [{label}] {q}")
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
        rows = (s.result.data_array if s.result else None) or []
        for r in rows[:30]:
            print(f"  {r}")
        if not rows:
            print("  (no rows)")
    else:
        print(f"  FAILED: {s.status.error.message if s.status.error else s.status.state}")

# Search across catalog/schemas
run("SHOW TABLES IN main.de_output", "tables in main.de_output")
run("SHOW TABLES IN main.de_output_stg", "tables in main.de_output_stg")
run("SHOW TABLES IN main.bi_db", "tables in main.bi_db (head only)")
