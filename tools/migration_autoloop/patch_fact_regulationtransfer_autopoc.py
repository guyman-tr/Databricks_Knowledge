#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
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
        r"set\s+V_maxloopdate\s*=\s*DATEADD\(day,\s*DATEDIFF\(0,\s*current_timestamp\(\)\),\s*0\)\s*;",
        "set V_maxloopdate = CAST(current_timestamp() AS DATE);",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"where\s+Occurred>=V_date\s+and\s+Occurred<V_auxdate;",
        ";",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"count\(\*\)\s+from\s+TEMP_TABLE_Reg",
        "count(*) from TEMP_TABLE_Reg where Occurred >= V_date and Occurred < V_auxdate",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"FROM\s+\n\s*TEMP_TABLE_Reg a\s*\n\s*left join",
        "FROM \n  TEMP_TABLE_Reg a\n  left join",
        out,
        flags=re.IGNORECASE,
    )
    out = out.replace(
        "on(a.CID=b.CID);",
        "on(a.CID=b.CID)\n  where a.Occurred >= V_date and a.Occurred < V_auxdate;",
    )
    return out


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    body = _patch(_fetch_body(w, wid, "sp_fact_regulationtransfer"))
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        "dwh_daily_process.migration_tables.sp_fact_regulationtransfer_autopoc(V_date TIMESTAMP) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("created_or_updated=sp_fact_regulationtransfer_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
