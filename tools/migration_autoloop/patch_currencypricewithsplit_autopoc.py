#!/usr/bin/env python3
"""Create AutoPOC patched proc for Fact_CurrencyPriceWithSplit flow."""
from __future__ import annotations

from pathlib import Path

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
    return str(rows[0][0] or "")


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
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    body = _fetch_proc_body(w, wid, "sp_fact_currencypricewithsplit_dl_to_synapse")

    # Make source row selection deterministic and date-scoped before MERGE.
    body_patched, qualify_count = re.subn(
        r"QUALIFY\s+ROW_NUMBER\(\)\s+OVER\s*\(\s*PARTITION\s+BY\s+a\.InstrumentID\s+ORDER\s+BY\s+1\s*\)\s*=\s*1",
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY a.InstrumentID, a.OccurredDateID ORDER BY a.Occurred DESC) = 1",
        body,
        count=1,
        flags=re.IGNORECASE,
    )
    if qualify_count != 1:
        raise RuntimeError("expected to patch one QUALIFY clause in source procedure")

    body_patched, on_count = re.subn(
        r"ON\s+a\.InstrumentID\s*=\s*a_TGT\.InstrumentID",
        "ON a.InstrumentID = a_TGT.InstrumentID AND a.OccurredDateID = a_TGT.OccurredDateID",
        body_patched,
        count=1,
        flags=re.IGNORECASE,
    )
    if on_count != 1:
        raise RuntimeError("expected to patch one MERGE ON clause in source procedure")

    _create_proc(
        w,
        wid,
        "sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
        "V_dt TIMESTAMP",
        body_patched,
    )
    print("created_or_updated=sp_fact_currencypricewithsplit_dl_to_synapse_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
