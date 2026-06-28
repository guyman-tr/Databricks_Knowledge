from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()
sql = """
CALL dwh_daily_process.migration_tables.sp_dim_position_dl_to_synapse(
  CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)
)
"""
try:
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=7200.0)
    print("ok")
except Exception as exc:
    print(str(exc))
