#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    procs = [
        "sp_dim_position_hedgetype_history_autopoc",
        "sp_dim_position_hedgetype_real_autopoc",
        "sp_dim_position_ispartialcloseparent_autopoc",
        "sp_dim_position_reopen_autopoc",
    ]
    for proc in procs:
        sql = (
            "CALL dwh_daily_process.migration_tables."
            f"{proc}(CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP))"
        )
        try:
            execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
            print(f"{proc}: OK")
        except Exception as exc:
            print(f"{proc}: FAIL")
            print(str(exc))
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
