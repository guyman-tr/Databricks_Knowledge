#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


PLAN = [
    ("sp_dim_position_hedgetype_history", "sp_dim_position_hedgetype_history_autopoc", "V_date TIMESTAMP"),
    ("sp_dim_position_hedgetype_real", "sp_dim_position_hedgetype_real_autopoc", "V_date TIMESTAMP"),
]


def _fetch_body(w, wid: str, routine_name: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{routine_name}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"source procedure definition not found: {routine_name}")
    return str(rows[0][0] or "")


def _patch_body(body: str) -> str:
    out = body
    out = re.sub(r"\bON\s+`?OpenDateID`?\b", "ON p.OpenDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bAND\s+`?OpenDateID`?\b", "AND p.OpenDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bON\s+`?CloseDateID`?\b", "ON p.CloseDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bAND\s+`?CloseDateID`?\b", "AND p.CloseDateID", out, flags=re.IGNORECASE)
    return out


def _create_proc(w, wid: str, name: str, signature: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{name}({signature}) "
        "LANGUAGE SQL "
        "SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for src, dst, sig in PLAN:
        patched = _patch_body(_fetch_body(w, wid, src))
        _create_proc(w, wid, dst, sig, patched)
        print(f"created_or_updated={dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
