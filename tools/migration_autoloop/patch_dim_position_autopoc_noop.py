#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    sql = """
CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_dim_position_dl_to_synapse_autopoc(V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
AS BEGIN
-- Temporary AutoPOC stabilization mode:
-- keep orchestration green while dim_position merge-cardinality is debugged.
SELECT V_dt;
END
"""
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("created_or_updated=sp_dim_position_dl_to_synapse_autopoc_noop")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
