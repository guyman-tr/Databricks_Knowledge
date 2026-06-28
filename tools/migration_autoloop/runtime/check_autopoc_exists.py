from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

NAMES = [
    "sp_dim_mirror_dl_to_synapse_autopoc",
    "sp_fact_deposit_state_autopoc",
    "sp_dictionaries_country_dl_to_synapse_autopoc",
    "sp_dim_position_dl_to_synapse_autopoc",
    "sp_dictionaries_dl_to_synapse_autopoc",
]

w = make_workspace_client()
wid = warehouse_id_from_env()
in_list = ",".join(f"'{n}'" for n in NAMES)
sql = (
    "SELECT routine_name "
    "FROM system.information_schema.routines "
    "WHERE routine_catalog='dwh_daily_process' "
    "AND routine_schema='migration_tables' "
    f"AND routine_name IN ({in_list}) "
    "ORDER BY 1"
)
_, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
print(rows)
