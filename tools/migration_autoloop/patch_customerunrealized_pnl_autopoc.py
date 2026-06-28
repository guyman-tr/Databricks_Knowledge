#!/usr/bin/env python3
"""Fix the customerunrealized_pnl autopoc helper's hardcoded run-date.

The codex-era autopoc clone of sp_fact_customerunrealized_pnl_autopoc inlined the
@RepDate as a LITERAL `DATE('2026-06-19')` everywhere (the "[autopoc] fixed run-date
expressions inlined" comment). The helper takes a real parameter `V_RepDate TIMESTAMP`
(passed by the orchestrator as V_dt) but ignored it. Effect: every run deleted+reinserted
the 20260619 slice while reading from whatever pinned daily_snapshot folder was current
(now etr_ymd=2026-06-21) -> it stamped 06-21 snapshot data as DateModified=20260619, so it
could never match gold's real 06-19, and the target stayed frozen at 06-19.

PnL is NOT recomputed here -- PnLInDollars / EndOfDayPnLInDollars are passthrough columns
from the EOD position snapshot. So once the run-date is parameter-driven and we run on the
day our snapshot actually holds (20260621), the slice should reproduce gold's 20260621.

Fix: the run-date must be dynamic but CANNOT appear inside the temp views as a script-local
variable (TEMP_TABLE_final_NOP_Notional etc.) -> LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION.
A session variable (DECLARE OR REPLACE VARIABLE) is ALSO illegal inside a BEGIN...END
scripting block (PARSE_SYNTAX_ERROR). So we materialize the run-date into a tiny 1-row Delta
table (fcupnl_rundate) as the first statement of the proc -- a local variable IS legal in a
top-level INSERT -- and every run-date reference becomes a scalar subquery against that table,
which is legal inside temp-view definitions (a view may read a table, just not a local var).

Idempotent: works whether the live body has the literal, the local-var form, or is already
patched to the subquery form.
"""
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

HELPER = "sp_fact_customerunrealized_pnl_autopoc"
LITERAL = "DATE('2026-06-19')"
LOCAL_EXPR = "CAST(V_RepDate AS DATE)"
RUNDATE_TBL = "dwh_daily_process.migration_tables.fcupnl_rundate"
SUBQ = f"(SELECT rd FROM {RUNDATE_TBL})"
SETUP = (
    "DECLARE V_row_count int;\n"
    f"INSERT OVERWRITE {RUNDATE_TBL} SELECT CAST(V_RepDate AS DATE) AS rd;"
)


def _fetch(w, wid, name: str) -> str:
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

    # 0) ensure the 1-row run-date table exists (no local var -> deploy-time safe)
    execute_sql(
        w,
        sql_text=f"CREATE TABLE IF NOT EXISTS {RUNDATE_TBL} (rd DATE) USING DELTA",
        warehouse_id=wid,
        poll_deadline_sec=300.0,
    )

    body = _fetch(w, wid, HELPER)

    # 1) point every run-date reference at the scalar subquery
    n_lit = body.count(LITERAL)
    n_loc = body.count(LOCAL_EXPR)
    fixed = body.replace(LITERAL, SUBQ).replace(LOCAL_EXPR, SUBQ)
    if LITERAL in fixed or LOCAL_EXPR in fixed:
        raise RuntimeError("replacement left a run-date ref behind")

    # 2) materialize the run-date once, before any temp view
    if f"INSERT OVERWRITE {RUNDATE_TBL}" not in fixed:
        if "DECLARE V_row_count int;" not in fixed:
            raise RuntimeError("anchor 'DECLARE V_row_count int;' not found for setup injection")
        fixed = fixed.replace("DECLARE V_row_count int;", SETUP, 1)

    sql = (
        f"CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.{HELPER}"
        f"(V_RepDate TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER AS {fixed}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=600.0)
    print(f"deployed={HELPER}  (run-date refs -> {SUBQ}; from literal={n_lit}, from local={n_loc})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
