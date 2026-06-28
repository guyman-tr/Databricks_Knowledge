#!/usr/bin/env python3
"""Patch sp_fact_regulationtransfer_autopoc for Databricks SQL compatibility.

Bug: the final loader defines `CREATE TEMPORARY VIEW TEMP_TABLE_Equity` whose
body references the scripting local variable `V_beforedateid`. Databricks
forbids local variables inside temp-object definitions
(LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION).

Fix: TEMP_TABLE_Equity is used exactly once (a LEFT JOIN in the final INSERT).
Drop the temp view and inline it as a subquery inside the INSERT, which is a
regular DML statement where local variables are allowed. TEMP_TABLE_Reg is left
untouched (its definition uses no local variable).
"""
from __future__ import annotations

import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

PROC = "sp_fact_regulationtransfer_autopoc"
INLINE = (
    "(SELECT * FROM dwh_daily_process.migration_tables.V_Liabilities "
    "WHERE DateID = V_beforedateid) b"
)


def _fetch_body(w, wid: str, name: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' AND routine_schema='migration_tables' "
            f"AND routine_name='{name}'"
        ),
        warehouse_id=wid,
    )
    if not rows or not rows[0][0]:
        raise RuntimeError(f"procedure body not found: {name}")
    return str(rows[0][0])


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    body = _fetch_body(w, wid, PROC)

    # 1) Neutralize the local-variable-bearing temp view definition.
    body, n1 = re.subn(
        r"CREATE\s+OR\s+REPLACE\s+TEMPORARY\s+VIEW\s+TEMP_TABLE_Equity\s+AS\s+select\s+\*\s+"
        r"from\s+dwh_daily_process\.migration_tables\.V_Liabilities\s+where\s+DateID\s*=\s*V_beforedateid\s*;",
        "SELECT 1;",
        body,
        count=1,
        flags=re.IGNORECASE,
    )
    if n1 != 1:
        raise RuntimeError(f"expected to neutralize 1 TEMP_TABLE_Equity view, got {n1}")

    # 2) Inline the temp view as a subquery in the INSERT's LEFT JOIN.
    body, n2 = re.subn(r"TEMP_TABLE_Equity\s+b\b", INLINE, body, count=1, flags=re.IGNORECASE)
    if n2 != 1:
        raise RuntimeError(f"expected to inline 1 TEMP_TABLE_Equity join, got {n2}")

    sql = (
        f"CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.{PROC}(V_date TIMESTAMP) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print(f"patched_and_deployed={PROC}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
