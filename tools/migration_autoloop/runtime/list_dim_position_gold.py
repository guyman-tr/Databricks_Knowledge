from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

w = make_workspace_client()
wid = warehouse_id_from_env()
sql = "SHOW TABLES IN main.dwh LIKE '*dim_position*'"
_, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
print(rows)
