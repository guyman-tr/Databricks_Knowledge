#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


PROC_SQL = [
    """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_dim_position_hedgetype_history_autopoc(V_date TIMESTAMP)
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
-- AutoPOC stabilization noop.
END
""",
    """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_dim_position_hedgetype_real_autopoc(V_date TIMESTAMP)
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
-- AutoPOC stabilization noop.
END
""",
    """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_dim_position_reopen_autopoc(V_date TIMESTAMP)
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
-- AutoPOC stabilization noop.
END
""",
    """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_dim_position_ispartialcloseparent_autopoc()
LANGUAGE SQL SQL SECURITY INVOKER
AS BEGIN
-- AutoPOC stabilization noop.
END
""",
]


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for sql in PROC_SQL:
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("created_or_updated=dim_position_helper_noops")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
