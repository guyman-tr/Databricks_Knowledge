from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState
import sys, time

w = WorkspaceClient(host="https://adb-5142916747090026.6.azuredatabricks.net", profile="guyman")
sql = sys.argv[1]
r = w.statement_execution.execute_statement(warehouse_id="208214768b0e0308", statement=sql, wait_timeout="50s")
if r.status.state in (StatementState.PENDING, StatementState.RUNNING):
    for _ in range(30):
        time.sleep(3)
        r = w.statement_execution.get_statement(r.statement_id)
        if r.status.state == StatementState.SUCCEEDED:
            break
if r.status.state == StatementState.FAILED:
    print(f"FAILED: {r.status.error.message}")
    sys.exit(1)
if r.result and r.result.data_array:
    cols = [c.name for c in r.manifest.schema.columns]
    print("\t".join(cols))
    for row in r.result.data_array:
        print("\t".join(str(v) for v in row))
else:
    print("No results")
