from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()
sql = """
SELECT statement_text, error_message, execution_status, start_time
FROM system.query.history
WHERE error_message LIKE '%DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE%'
ORDER BY start_time DESC
LIMIT 10
"""
cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
print(cols)
for r in rows:
    print("----")
    print(r)
