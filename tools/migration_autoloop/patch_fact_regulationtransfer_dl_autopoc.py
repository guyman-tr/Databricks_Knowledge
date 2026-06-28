#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _fetch_body(w, wid: str, proc: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{proc}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"missing source procedure: {proc}")
    return str(rows[0][0] or "")


def _patch(body: str) -> str:
    out = body
    out = re.sub(
        r"SET\s+V_CurrentDate\s*=\s*cast\(DATEADD\(day,\s*DATEDIFF\(-1,\s*V_dt\),\s*0\)\s+as\s+date\)\s*;",
        "SET V_CurrentDate = DATEADD(day, 1, CAST(V_dt AS DATE));",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Fact_RegulationTransfer\s*\(\s*V_dt\s*\)\s*;",
        "call dwh_daily_process.migration_tables.sp_fact_regulationtransfer_autopoc(V_dt);",
        out,
        flags=re.IGNORECASE,
    )
    return out


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    body = _patch(_fetch_body(w, wid, "sp_fact_regulationtransfer_dl_to_synapse"))
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        "dwh_daily_process.migration_tables.sp_fact_regulationtransfer_dl_to_synapse_autopoc(V_dt TIMESTAMP) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("created_or_updated=sp_fact_regulationtransfer_dl_to_synapse_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
