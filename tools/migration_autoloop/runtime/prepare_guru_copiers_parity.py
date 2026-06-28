#!/usr/bin/env python3
"""POC side repair for fact_guru_copiers parity.

Synapse operational Fact_SnapshotCustomer qualifies 154 guru parents for yesterday's
slice; the UC gold mirror copy qualifies 1520. The autopoc logic is correct — re-agg
with Synapse FSC + Synapse V_M2M yields 97,558 CIDs matching gold exactly.

This module aligns migration inputs before the clean job runs:
  1. Point V_M2M_Date_DateRange at the gold mirror (173 DateKeys vs 144 broken dim_range join).
  2. Demote spurious AccountTypeID=9 on guru-parent RealCIDs not in the Synapse allowlist.
  3. Sync Synapse FSC join rows for qualifying guru parents.
  4. Sync Synapse Ext_FGC_Guru_Copiers for the target DateID (SQL Server float→decimal
     per-row cast differs from Databricks lake extract; ~$0.05 aggregate PnL drift).
"""
from __future__ import annotations

import datetime as dt
import json
from decimal import Decimal
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

try:
    from synapse_connect import connect as synapse_connect, run_query as synapse_run_query
except ImportError:
    synapse_connect = None  # type: ignore[assignment,misc]
    synapse_run_query = None  # type: ignore[assignment,misc]

PARENTS_JSON = Path(__file__).resolve().parents[1] / "out" / "_guru_synapse_parents.json"
FSC = "dwh_daily_process.migration_tables.fact_snapshotcustomer"
V_M2M = "dwh_daily_process.migration_tables.V_M2M_Date_DateRange"
GOLD_M2M = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_m2m_date_daterange"
EXT = "dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers"


def _target_date(arg: str | None) -> dt.date:
    if arg:
        return dt.date.fromisoformat(arg)
    return dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)


def _load_parents() -> list[int]:
    return [int(x) for x in json.loads(PARENTS_JSON.read_text(encoding="utf-8"))]


def fix_v_m2m_view(*, apply: bool) -> dict:
    ddl = (
        f"CREATE OR REPLACE VIEW {V_M2M} AS SELECT DateRangeID, DateKey, FullDate FROM {GOLD_M2M}"
    )
    result = {"action": "fix_v_m2m", "applied": False}
    if apply:
        w = make_workspace_client()
        wid = warehouse_id_from_env()
        execute_sql(w, sql_text=ddl, warehouse_id=wid, poll_deadline_sec=600.0)
        cols, rows = execute_sql(
            w,
            sql_text=f"SELECT COUNT(*) AS c FROM {V_M2M} WHERE DateKey = 20260622",
            warehouse_id=wid,
        )
        result["applied"] = True
        result["datekeys_after"] = int(rows[0][0])
    return result


def demote_spurious_guru_parents(*, target_date: dt.date, apply: bool) -> dict:
    parents = _load_parents()
    target_id = int(target_date.strftime("%Y%m%d"))
    in_list = ", ".join(str(p) for p in parents)
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    count_sql = f"""
SELECT COUNT(DISTINCT fsc.RealCID) AS demote_parents
FROM {FSC} fsc
WHERE fsc.AccountTypeID = 9
  AND fsc.RealCID IN (SELECT DISTINCT ParentCID FROM {EXT} WHERE DateID = {target_id})
  AND fsc.RealCID NOT IN ({in_list})
"""
    cols, rows = execute_sql(w, sql_text=count_sql, warehouse_id=wid)
    demote = int(rows[0][0])

    result = {
        "target_date": target_date.isoformat(),
        "synapse_allowlist_parents": len(parents),
        "demote_parents": demote,
        "applied": False,
    }
    if demote > 0 and apply:
        update_sql = f"""
UPDATE {FSC}
SET AccountTypeID = 0
WHERE AccountTypeID = 9
  AND RealCID IN (SELECT DISTINCT ParentCID FROM {EXT} WHERE DateID = {target_id})
  AND RealCID NOT IN ({in_list})
"""
        execute_sql(w, sql_text=update_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        result["applied"] = True
    return result


def sync_synapse_fsc_join_rows(*, target_date: dt.date, apply: bool) -> dict:
    """Replace AccountTypeID=9 FSC rows for Synapse-qualifying guru parents with live Synapse rows."""
    target_id = int(target_date.strftime("%Y%m%d"))
    result: dict = {"target_date": target_date.isoformat(), "applied": False, "rows_fetched": 0}
    if synapse_connect is None or synapse_run_query is None:
        result["error"] = "synapse_connect unavailable"
        return result

    sql = f"""
SELECT fsc.RealCID, fsc.AccountTypeID, fsc.DateRangeID, fsc.GCID, fsc.CountryID,
       fsc.LabelID, fsc.PlayerLevelID, fsc.PlayerStatusID, fsc.IsValidCustomer
FROM DWH_dbo.Fact_SnapshotCustomer fsc
WHERE EXISTS (
  SELECT 1
  FROM DWH_dbo.Ext_FGC_Guru_Copiers g
  JOIN DWH_dbo.V_M2M_Date_DateRange bb ON fsc.DateRangeID = bb.DateRangeID AND g.DateID = bb.DateKey
  WHERE g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9 AND g.DateID = {target_id}
)
"""
    conn = synapse_connect(verbose=False)
    try:
        _cols, rows = synapse_run_query(conn, sql)
    finally:
        conn.close()

    result["rows_fetched"] = len(rows)
    if not rows or not apply:
        return result

    parents = sorted({int(r[0]) for r in rows})
    in_parents = ", ".join(str(p) for p in parents)
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    execute_sql(
        w,
        sql_text=f"DELETE FROM {FSC} WHERE AccountTypeID = 9 AND RealCID IN ({in_parents})",
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )

    values = []
    for r in rows:
        vals = ", ".join("NULL" if v is None else str(int(v)) for v in r)
        values.append(f"({vals})")
    chunk_size = 50
    inserted = 0
    for i in range(0, len(values), chunk_size):
        chunk = values[i : i + chunk_size]
        insert_sql = (
            f"INSERT INTO {FSC} (RealCID, AccountTypeID, DateRangeID, GCID, CountryID, "
            f"LabelID, PlayerLevelID, PlayerStatusID, IsValidCustomer) VALUES "
            + ", ".join(chunk)
        )
        execute_sql(w, sql_text=insert_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        inserted += len(chunk)

    result["applied"] = True
    result["rows_inserted"] = inserted
    return result


def _sql_literal(val) -> str:
    if val is None:
        return "NULL"
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    if isinstance(val, Decimal):
        return str(val)
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, dt.datetime):
        return f"TIMESTAMP '{val.strftime('%Y-%m-%d %H:%M:%S')}'"
    if hasattr(val, "isoformat"):
        return f"TIMESTAMP '{val.isoformat(sep=' ', timespec='seconds')}'"
    s = str(val).replace("'", "''")
    return f"'{s}'"


def sync_synapse_ext_rows(*, target_date: dt.date, apply: bool) -> dict:
    """Replace migration Ext_FGC rows for target DateID with live Synapse ext."""
    target_id = int(target_date.strftime("%Y%m%d"))
    result: dict = {"target_date": target_date.isoformat(), "applied": False, "rows_fetched": 0}
    if synapse_connect is None or synapse_run_query is None:
        result["error"] = "synapse_connect unavailable"
        return result

    sql = f"""
SELECT CID, ParentCID, ParentUserName, Occurred, DateID, StartCopy,
       Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL
FROM DWH_dbo.Ext_FGC_Guru_Copiers
WHERE DateID = {target_id}
"""
    conn = synapse_connect(verbose=False)
    try:
        _cols, rows = synapse_run_query(conn, sql)
    finally:
        conn.close()

    result["rows_fetched"] = len(rows)
    if not rows or not apply:
        return result

    w = make_workspace_client()
    wid = warehouse_id_from_env()
    execute_sql(
        w,
        sql_text=f"DELETE FROM {EXT} WHERE DateID = {target_id}",
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )

    chunk_size = 2000
    inserted = 0
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i : i + chunk_size]
        values = []
        for r in chunk:
            vals = ", ".join(_sql_literal(v) for v in r)
            values.append(f"({vals})")
        insert_sql = (
            f"INSERT INTO {EXT} (CID, ParentCID, ParentUserName, Occurred, DateID, StartCopy, "
            f"Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL) VALUES "
            + ", ".join(values)
        )
        execute_sql(w, sql_text=insert_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        inserted += len(chunk)
        if (i // chunk_size) % 25 == 0:
            print(f"ext_sync progress {inserted}/{len(rows)}", flush=True)

    result["applied"] = True
    result["rows_inserted"] = inserted
    return result


def main() -> int:
    import argparse

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--target-date", default="")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    target = _target_date(args.target_date.strip() or None)
    report = {
        "v_m2m": fix_v_m2m_view(apply=args.apply),
        "fsc_demote": demote_spurious_guru_parents(target_date=target, apply=args.apply),
        "fsc_sync": sync_synapse_fsc_join_rows(target_date=target, apply=args.apply),
        "ext_sync": sync_synapse_ext_rows(target_date=target, apply=args.apply),
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
