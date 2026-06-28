#!/usr/bin/env python3
"""Create AutoPOC patched procs for Fact_CustomerUnrealized_PnL flow."""
from __future__ import annotations

from pathlib import Path
import argparse
import datetime as dt

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

import re

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _fetch_proc_body(workspace_client, warehouse_id: str, routine_name: str) -> str:
    _, rows = execute_sql(
        workspace_client,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{routine_name}'"
        ),
        warehouse_id=warehouse_id,
    )
    if not rows:
        raise RuntimeError(f"source procedure definition not found: {routine_name}")
    return rows[0][0]


def _create_proc(workspace_client, warehouse_id: str, name: str, param_sig: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{name}({param_sig}) "
        "LANGUAGE SQL "
        "SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(workspace_client, sql_text=sql, warehouse_id=warehouse_id, poll_deadline_sec=1800.0)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--run-date",
        default="",
        help="Target run date YYYY-MM-DD. Defaults to yesterday UTC.",
    )
    args = ap.parse_args()
    run_date = args.run_date.strip() or (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()

    w = make_workspace_client()
    wid = warehouse_id_from_env()

    main_body = _fetch_proc_body(w, wid, "sp_fact_customerunrealized_pnl")
    # Drop unsupported debug helper calls.
    # Remove unsupported debug-helper CALL statements deterministically.
    main_parts = main_body.split(";")
    kept_parts: list[str] = []
    for part in main_parts:
        if "LastRowCount" in part:
            kept_parts.append("-- [autopoc] removed call dbo.LastRowCount(...)")
            continue
        kept_parts.append(part)
    main_body_patched = ";".join(kept_parts)
    # Replace local-variable references with parameter-driven expressions so
    # temp-view definitions do not reference scripting locals while still
    # honoring the caller-provided run date.
    fixed_repdate_expr = f"DATE('{run_date}')"
    # Keep legacy +1 day runtime semantics from Synapse:
    # StartDate is used as an exclusive upper bound in OpenOccurred filters.
    fixed_startdate_expr = f"DATE_ADD(DATE('{run_date}'), 1)"
    fixed_dateid_expr = f"CAST(date_format(DATE('{run_date}'), 'yyyyMMdd') AS int)"

    main_body_patched = re.sub(
        r"DECLARE\s+V_dateid\s+int\s*;",
        "",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    main_body_patched = re.sub(
        r"DECLARE\s+V_StartDate\s+date\s*;",
        "",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    main_body_patched = re.sub(
        r"set\s+V_dateid\s*=\s*CAST\(date_format\(V_RepDate,\s*'yyyyMMdd'\)\s*AS\s*int\)\s*;\s*SET\s+V_StartDate\s*=\s*DATEADD\(day,\s*1,\s*V_RepDate\)\s*;",
        "-- [autopoc] fixed run-date expressions inlined",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    main_body_patched = re.sub(r"\bV_dateid\b", fixed_dateid_expr, main_body_patched)
    main_body_patched = re.sub(r"\bV_StartDate\b", fixed_startdate_expr, main_body_patched)
    main_body_patched = re.sub(r"\bV_RepDate\b", fixed_repdate_expr, main_body_patched)
    # Price selection should be as-of run date (latest candle up to run date),
    # not strict equality, to avoid empty joins on backfill days.
    main_body_patched = main_body_patched.replace(
        f"OccurredDate = {fixed_startdate_expr}",
        f"OccurredDate <= {fixed_startdate_expr}",
    )
    main_body_patched = main_body_patched.replace(
        f"OccurredDate={fixed_startdate_expr}",
        f"OccurredDate<={fixed_startdate_expr}",
    )
    # Databricks compares DATE to compact YYYYMMDD string as NULL.
    # This caused the guarded insert block to be skipped entirely.
    main_body_patched = re.sub(
        r">=\s*'20121231'",
        ">= DATE('2012-12-31')",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    # SQL Server-style week-bucket expression (DATEDIFF(...,0)) is invalid in DBX.
    main_body_patched = re.sub(
        r"CAST\(date_format\(DATEADD\(day,\s*-1,\s*DATEADD\(week,\s*DATEDIFF\(week,\s*DATE\('[0-9\-]+'\),\s*0\),\s*0\)\),\s*'yyyyMMdd'\)\s*AS\s*int\)",
        f"CAST(date_format(DATE_SUB(DATE_TRUNC('WEEK', DATE('{run_date}')), 1), 'yyyyMMdd') AS int)",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    # M2M daterange lookup lives in main.dwh, not migration_tables.
    main_body_patched = re.sub(
        r"dwh_daily_process\.migration_tables\.V_M2M_Date_DateRange",
        "main.dwh.v_m2m_date_daterange",
        main_body_patched,
        flags=re.IGNORECASE,
    )
    # Persist stage row-count breadcrumbs so we can see exactly where the flow
    # collapses when final INSERT returns zero rows.
    debug_prefix = (
        "CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_tables.fcupnl_debug_counts ("
        "run_date_id INT, captured_at TIMESTAMP, prices_cnt BIGINT, open_positions_cnt BIGINT, "
        "open_positions_final_cnt BIGINT, end_conv_cnt BIGINT, unrealized_cnt BIGINT, "
        "unrealized_filtered_cnt BIGINT) USING DELTA;"
        "INSERT INTO dwh_daily_process.migration_tables.fcupnl_debug_counts "
        "SELECT "
        f"{fixed_dateid_expr}, current_timestamp(), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_Prices), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_OpenPositions), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_OpenPositionsFinal), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_EndConvertionRate), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_UnrealizedPnL), "
        "(SELECT COUNT(*) FROM TEMP_TABLE_UnrealizedPnL WHERE PnLInDollars IS NOT NULL AND CalculatedNetProfit IS NOT NULL);"
    )
    main_body_patched = re.sub(
        r"insert\s+into\s+dwh_daily_process\.migration_tables\.fact_customerunrealized_pnl",
        debug_prefix + "INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL",
        main_body_patched,
        count=1,
        flags=re.IGNORECASE,
    )
    _create_proc(
        w,
        wid,
        "sp_fact_customerunrealized_pnl_autopoc",
        "V_RepDate TIMESTAMP",
        main_body_patched,
    )

    dl_body = _fetch_proc_body(w, wid, "sp_fact_customerunrealized_pnl_dl_to_synapse")
    dl_body_patched = dl_body.replace(
        "call dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation(V_dt);",
        "-- [autopoc] skipped SP_Dim_Instrument_Correlation(V_dt)",
    )
    dl_body_patched = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Fact_CustomerUnrealized_PnL\s*\(V_dt\);",
        "call dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_autopoc(V_dt);",
        dl_body_patched,
        flags=re.IGNORECASE,
    )
    # Route problematic daily_snapshot views through migration_tables views
    # we can safely recreate per-run (no MANAGE permission on daily_snapshot objects).
    dl_body_patched = re.sub(
        r"dwh_daily_process\.daily_snapshot\.etoro_History_BackOfficeCustomer",
        "dwh_daily_process.migration_tables.vw_fcupnl_backofficecustomer_target",
        dl_body_patched,
        flags=re.IGNORECASE,
    )
    dl_body_patched = re.sub(
        r"dwh_daily_process\.daily_snapshot\.PriceLog_Candles_CurrencyPriceMaxDate",
        "dwh_daily_process.migration_tables.vw_fcupnl_currencypricemaxdate_target",
        dl_body_patched,
        flags=re.IGNORECASE,
    )
    _create_proc(
        w,
        wid,
        "sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
        "V_dt TIMESTAMP",
        dl_body_patched,
    )
    print("created_or_updated=sp_fact_customerunrealized_pnl_autopoc")
    print("created_or_updated=sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

