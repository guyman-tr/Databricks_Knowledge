from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import make_workspace_client, warehouse_id_from_env, execute_sql
from tools.migration_autoloop.flow_catalog import MULTI_TASK_FLOW_CATALOG
import json

w = make_workspace_client()
wid = warehouse_id_from_env()
flow = MULTI_TASK_FLOW_CATALOG["fact_customeraction_etl"]
out = []
for c in flow.children:
    sql = f"CALL dwh_daily_process.migration_tables.{c.procedure_name}(TIMESTAMP '2026-06-19')"
    try:
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=300.0)
        out.append({"flow_id": c.flow_id, "proc": c.procedure_name, "status": "ok"})
    except Exception as e:
        out.append({"flow_id": c.flow_id, "proc": c.procedure_name, "status": "error", "error": str(e)[:400]})

print(json.dumps(out, indent=2))
