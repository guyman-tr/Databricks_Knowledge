from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()
sql = """
SELECT start_time, execution_status, statement_text, error_message
FROM system.query.history
WHERE start_time >= DATEADD(HOUR, -2, current_timestamp())
  AND (
    statement_text LIKE '%sp_dim_position_dl_to_synapse_autopoc%'
    OR statement_text LIKE 'MERGE INTO dwh_daily_process.migration_tables.%'
  )
ORDER BY start_time DESC
LIMIT 200
"""
cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
print(cols)
for r in rows:
    print("----")
    print(r[0], r[1])
    print((r[2] or "")[:500].replace("\n", " "))
    if r[3]:
        print("ERR:", str(r[3])[:400].replace("\n", " "))
