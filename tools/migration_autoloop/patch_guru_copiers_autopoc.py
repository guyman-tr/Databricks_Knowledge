#!/usr/bin/env python3
"""Build DBSQL-clean _autopoc procs for fact_guru_copiers.

POC parity: ext is pre-loaded from Synapse operational Ext_FGC_Guru_Copiers by
prepare_guru_copiers_parity.py (lake double→decimal cast does not match SQL Server).
The autopoc orchestrator skips lake extract; helper uses simple SUM like Synapse SP.
"""
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

EXT_TABLE = "dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers"

EXT_DDL = f"""
CREATE OR REPLACE TABLE {EXT_TABLE} (
  CID BIGINT,
  ParentCID BIGINT,
  ParentUserName STRING,
  Occurred TIMESTAMP,
  DateID INT,
  StartCopy TIMESTAMP,
  Cash DECIMAL(19,4),
  Investment DECIMAL(19,4),
  PnL DECIMAL(19,4),
  DetachedPosInvestment DECIMAL(19,4),
  Dit_PnL DECIMAL(19,4)
)
""".strip()

_EXTRACT_START = "TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers"
_EXTRACT_END = "-- Execute SP_Fact_Guru_Copiers"


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


def _strip_lake_extract(body: str) -> str:
    """Remove TRUNCATE+INSERT ext block; POC loads ext from Synapse before the job."""
    start = body.find(_EXTRACT_START)
    end = body.find(_EXTRACT_END)
    if start < 0 or end < 0 or end <= start:
        raise RuntimeError("failed to locate ext extract block in orchestrator")
    stripped = body[:start] + "-- POC: ext pre-synced from Synapse; lake extract elided.\n" + body[end:]
    if _EXTRACT_START in stripped:
        raise RuntimeError("ext extract block still present after strip")
    return stripped


def _patch_orchestrator(body: str) -> str:
    o = body
    o = o.replace("date_format(TIMESTAMP,", "date_format(`TIMESTAMP`,")
    o = o.replace("WHERE TIMESTAMP = V_Yesterday", "WHERE `TIMESTAMP` = V_Yesterday")
    o = o.replace(
        "migration_tables.SP_Fact_Guru_Copiers(V_Yesterday)",
        "migration_tables.sp_fact_guru_copiers_autopoc(V_Yesterday)",
    )
    o = _strip_lake_extract(o)
    return o


def ensure_ext_table(w, wid) -> None:
    execute_sql(w, sql_text=EXT_DDL, warehouse_id=wid, poll_deadline_sec=600.0)
    print(f"recreated={EXT_TABLE}")


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    helper = _fetch(w, wid, "sp_fact_guru_copiers")
    orch = _patch_orchestrator(_fetch(w, wid, "sp_fact_guru_copiers_dl_to_synapse"))

    ensure_ext_table(w, wid)

    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_guru_copiers_autopoc"
            f"(V_dt TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER AS {helper}"
        ),
        warehouse_id=wid,
        poll_deadline_sec=600.0,
    )
    print("deployed=sp_fact_guru_copiers_autopoc")

    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_guru_copiers_dl_to_synapse_autopoc"
            f"(V_dt TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER AS {orch}"
        ),
        warehouse_id=wid,
        poll_deadline_sec=600.0,
    )
    print("deployed=sp_fact_guru_copiers_dl_to_synapse_autopoc (extract elided)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
