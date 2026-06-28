#!/usr/bin/env python3
"""Patch snapshotcustomer procedures into Databricks-friendly AutoPOC variants."""
from __future__ import annotations

import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


PROC_MAP = {
    "sp_fact_snapshotcustomer": ("sp_fact_snapshotcustomer_autopoc", "V_date TIMESTAMP"),
    "sp_fact_snapshotcustomer_dl_to_synapse": ("sp_fact_snapshotcustomer_dl_to_synapse_autopoc", "V_dt TIMESTAMP"),
}


def _fetch_body(w, wid: str, src_proc: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{src_proc}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"Missing source procedure: {src_proc}")
    return str(rows[0][0] or "")


def _patch_wrapper_date_idioms(body: str) -> str:
    out = body
    out = out.replace(
        "SET V_CurrentDate = cast(DATEADD(day, DATEDIFF(-1, V_dt), 0) as date);",
        "SET V_CurrentDate = CAST(DATEADD(DAY, 1, CAST(V_dt AS DATE)) AS DATE);",
    )
    out = out.replace(
        "SET V_St_Year = convert(TIMESTAMP,DATEADD(YEAR, CAST(DATEDIFF(0, V_dt) / 365 AS INT), 0),8);",
        "SET V_St_Year = CAST(DATE_TRUNC('YEAR', CAST(V_dt AS DATE)) AS STRING);",
    )
    return out


def _patch_cross_proc_call(body: str) -> str:
    return re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Fact_SnapshotCustomer\s*\(",
        "call dwh_daily_process.migration_tables.sp_fact_snapshotcustomer_autopoc(",
        body,
        flags=re.IGNORECASE,
    )


def _patch_core_date_idioms(body: str) -> str:
    out = body
    out = out.replace(
        "DATEADD(YEAR, CAST(DATEDIFF(0, current_timestamp()) / 365 AS INT), 0)",
        "DATE_TRUNC('YEAR', current_timestamp())",
    )
    out = out.replace(
        "case when  DATE_TRUNC('YEAR', current_timestamp()) =  V_date then V_date",
        "case when DATE_TRUNC('YEAR', current_timestamp()) = CAST(DATEADD(DAY, -1, current_date()) AS DATE) then CAST(DATEADD(DAY, -1, current_date()) AS DATE)",
    )
    out = re.sub(
        r"\(\s*case\s+when[\s\S]*?V_maxentrydate[\s\S]*?end\s*\)",
        "(CAST(MAKE_DATE(YEAR(DATEADD(DAY, -1, current_date())), 12, 31) AS TIMESTAMP))",
        out,
        count=1,
        flags=re.IGNORECASE,
    )
    out = out.replace(
        "CASE WHEN PhoneVerifiedID IN (1, 2) THEN 1 ELSE 0 END AS IsPhoneVerified",
        "CASE WHEN CAST(PhoneVerifiedID AS INT) IN (1, 2) THEN 1 ELSE 0 END AS IsPhoneVerified",
    )
    out = out.replace(
        "coalesce(TEMP_TABLE_DepositorChanges.IsDepositor, FSC.IsDepositor,0) AS IsDepositor",
        "COALESCE(CAST(TEMP_TABLE_DepositorChanges.IsDepositor AS INT), CAST(FSC.IsDepositor AS INT), 0) AS IsDepositor",
    )
    out = out.replace(
        "coalesce(PVD.IsPhoneVerified, FSC.IsPhoneVerified,0) AS IsPhoneVerified",
        "COALESCE(CAST(PVD.IsPhoneVerified AS INT), CAST(FSC.IsPhoneVerified AS INT), 0) AS IsPhoneVerified",
    )
    out = out.replace(
        "(COALESCE(CAST(a.IsPhoneVerified AS BOOLEAN), -1) <> COALESCE(CAST(b.IsPhoneVerified AS BOOLEAN), -1)) OR",
        "(COALESCE(CAST(a.IsPhoneVerified AS INT), -1) <> COALESCE(CAST(b.IsPhoneVerified AS INT), -1)) OR",
    )
    return out


def _create_proc(w, wid: str, dst_proc: str, param_sig: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{dst_proc}({param_sig}) "
        "LANGUAGE SQL "
        "SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for src_proc, (dst_proc, param_sig) in PROC_MAP.items():
        body = _fetch_body(w, wid, src_proc)
        if src_proc == "sp_fact_snapshotcustomer_dl_to_synapse":
            patched = _patch_wrapper_date_idioms(body)
            patched = _patch_cross_proc_call(patched)
        else:
            patched = _patch_core_date_idioms(body)
        _create_proc(w, wid, dst_proc, param_sig, patched)
        print(f"created_or_updated={dst_proc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
