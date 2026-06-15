"""Find the most recent dates with data in the DDR revenue table."""
from __future__ import annotations
import time, os
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

w = WorkspaceClient()
warehouse_id = os.environ.get("DATABRICKS_WAREHOUSE_ID") or next(w.warehouses.list()).id

q = "SHOW TABLES IN main.de_output"
resp = w.statement_execution.execute_statement(statement=q, warehouse_id=warehouse_id, wait_timeout="30s")
sid = resp.statement_id
while True:
    s = w.statement_execution.get_statement(sid)
    if s.status.state in (StatementState.SUCCEEDED, StatementState.FAILED, StatementState.CANCELED):
        break
    time.sleep(0.5)
if s.status.state == StatementState.SUCCEEDED:
    rows = (s.result.data_array if s.result else None) or []
    for r in rows:
        if 'ddr' in str(r[1]).lower() or 'fact' in str(r[1]).lower() or 'kpi' in str(r[1]).lower():
            print(f"  {r[1]}")
else:
    print(f"FAILED: {s.status.error.message if s.status.error else s.status.state}")
