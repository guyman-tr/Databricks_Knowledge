#!/usr/bin/env python3
"""Clone an existing migration_tables procedure to a `<name>_autopoc` variant.

Used to bring a proc into the AutoPOC framework naming without changing logic.
Fetches the live routine_definition (body) and parameter signature, then
re-deploys it under the _autopoc name.
"""
from __future__ import annotations

import argparse
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

SCHEMA = "dwh_daily_process.migration_tables"


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


def _fetch_params(w, wid: str, name: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT p.parameter_name, p.data_type FROM system.information_schema.parameters p "
            "JOIN system.information_schema.routines r ON p.specific_name=r.specific_name "
            "WHERE r.routine_catalog='dwh_daily_process' AND r.routine_schema='migration_tables' "
            f"AND r.routine_name='{name}' ORDER BY p.ordinal_position"
        ),
        warehouse_id=wid,
    )
    parts = [f"{r[0]} {r[1]}" for r in rows if r[0]]
    return ", ".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, help="source proc name (no schema)")
    ap.add_argument("--target", required=True, help="target proc name (no schema)")
    args = ap.parse_args()

    w = make_workspace_client()
    wid = warehouse_id_from_env()
    body = _fetch_body(w, wid, args.source)
    params = _fetch_params(w, wid, args.source)

    sql = (
        f"CREATE OR REPLACE PROCEDURE {SCHEMA}.{args.target}({params}) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print(f"cloned {args.source} -> {args.target} (params: {params or 'none'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
