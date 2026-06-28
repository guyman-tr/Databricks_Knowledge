from pathlib import Path
import sys
import datetime as dt
import json

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import make_workspace_client, warehouse_id_from_env, execute_sql
from tools.migration_autoloop.run_flow_autoloop_report import (
    _query_table_columns,
    _date_filter,
    _metric_columns,
    _aggregates,
    _metric_deltas,
    _bool_pass,
)

w = make_workspace_client()
wid = warehouse_id_from_env()
target_date = dt.date.fromisoformat("2026-06-19")

execute_sql(
    w,
    sql_text="CALL dwh_daily_process.migration_tables.sp_dictionaries_country_dl_to_synapse()",
    warehouse_id=wid,
    poll_deadline_sec=600.0,
)

migration = "dwh_daily_process.migration_tables.dim_country"
gold = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country"

cols = _query_table_columns(migration)
gcols = _query_table_columns(gold)
where_mig, where_col = _date_filter(cols, target_date, dialect="dbx")
where_gold, _ = _date_filter(gcols, target_date, preferred_column=where_col, dialect="dbx")
metrics = [m for m in _metric_columns(cols) if m in {str(c["column_name"]) for c in gcols}][:3]

post = _aggregates(migration, where_mig, metrics)
gold_vals = _aggregates(gold, where_gold, metrics)
delta = _metric_deltas(post, gold_vals, metrics)

print(
    json.dumps(
        {
            "where_migration": where_mig,
            "where_gold": where_gold,
            "metrics": metrics,
            "post": post,
            "gold": gold_vals,
            "delta": delta,
            "pass": _bool_pass(delta, metrics),
        },
        indent=2,
    )
)
