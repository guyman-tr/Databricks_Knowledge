#!/usr/bin/env python3
"""Clone history_cost procs to _autopoc.

Both the orchestrator (sp_fact_history_cost_dl_to_synapse) and helper
(sp_fact_history_cost) are already DBSQL-clean:
  - DateID = CAST(date_format(Occurred,'yyyyMMdd') AS int)
  - "FROM Fact_History_Cost NOLOCK" parses as table alias NOLOCK (harmless,
    and the V_row_count it feeds is dead/unused).
  - Single-day CDC: snapshot HistoryCosts_History_Costs holds one day; the
    orchestrator TRUNCATEs Ext_History_Cost, full-loads the snapshot, the helper
    deletes that day from Fact and reinserts the whole Ext (= that one day).

The only change for the autopoc orchestrator is to CALL the autopoc helper.
"""
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _fetch(w, wid, name):
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition FROM dwh_daily_process.information_schema.routines "
            f"WHERE specific_schema='migration_tables' AND routine_name='{name}'"
        ),
        warehouse_id=wid,
    )
    if not rows or not rows[0][0]:
        raise RuntimeError(f"not found: {name}")
    return str(rows[0][0])


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    helper = _fetch(w, wid, "sp_fact_history_cost")
    orch = _fetch(w, wid, "sp_fact_history_cost_dl_to_synapse")

    # repoint orchestrator helper call to the autopoc helper
    orch2 = orch.replace(
        "dwh_daily_process.migration_tables.SP_Fact_History_Cost(V_Yesterday)",
        "dwh_daily_process.migration_tables.sp_fact_history_cost_autopoc(V_Yesterday)",
    )
    if orch2 == orch:
        raise RuntimeError("failed to repoint helper call in orchestrator")

    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_history_cost_autopoc"
            f"(V_dt TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER AS {helper}"
        ),
        warehouse_id=wid,
        poll_deadline_sec=600.0,
    )
    print("deployed=sp_fact_history_cost_autopoc")

    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_history_cost_dl_to_synapse_autopoc"
            f"(V_dt TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER AS {orch2}"
        ),
        warehouse_id=wid,
        poll_deadline_sec=600.0,
    )
    print("deployed=sp_fact_history_cost_dl_to_synapse_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
