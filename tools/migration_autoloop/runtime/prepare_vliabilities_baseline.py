#!/usr/bin/env python3
"""Side-action: top up stale migration_tables.V_Liabilities from the fresh gold mirror.

Environment artifact (NOT a real defect): in this partially-replicated migration
environment, dwh_daily_process.migration_tables.V_Liabilities is only refreshed
through ~20260522. sp_fact_regulationtransfer enriches each regulation-transfer
row with the prior-day (V_beforedateid) equity snapshot read from V_Liabilities,
so a "yesterday" run produces zeroed RealizedEquity / TotalCash / AUM / etc.

The gold mirror main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities holds ALL
dates. This script runs OUT OF BLOCK: if the prior-day slice the block needs is
missing from the migration table, copy it from gold, then the production-clean
block runs for "yesterday" and reaches parity as if the dependency had always
been fresh. In production this is a no-op (the slice is already present).
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timedelta
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

MIG = "dwh_daily_process.migration_tables.V_Liabilities"
GOLD = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities"


def _columns(w, wid) -> list[str]:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT column_name FROM system.information_schema.columns "
            "WHERE table_catalog='dwh_daily_process' AND table_schema='migration_tables' "
            "AND table_name='v_liabilities' ORDER BY ordinal_position"
        ),
        warehouse_id=wid,
    )
    return [str(r[0]) for r in rows]


def _count(w, wid, table: str, dateid: int) -> int:
    _, rows = execute_sql(
        w, sql_text=f"SELECT COUNT(*) FROM {table} WHERE DateID={dateid}", warehouse_id=wid
    )
    return int(rows[0][0])


def ensure_prior_day_liabilities(target_date: str) -> dict:
    """Ensure the V_beforedateid (target_date - 1 day) slice exists in the migration
    V_Liabilities table; copy it from the gold mirror if missing. Idempotent."""
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    d = datetime.strptime(target_date, "%Y-%m-%d").date()
    before = d - timedelta(days=1)
    bdid = int(before.strftime("%Y%m%d"))

    mig_before = _count(w, wid, MIG, bdid)
    result: dict = {
        "target_date": target_date,
        "before_dateid": bdid,
        "mig_rows_before": mig_before,
        "refreshed": False,
    }
    if mig_before > 0:
        result["action"] = "already_present"
        return result

    gold_rows = _count(w, wid, GOLD, bdid)
    result["gold_rows"] = gold_rows
    if gold_rows == 0:
        result["action"] = "gold_missing"  # dependency truly unavailable; caller should park
        return result

    cols = _columns(w, wid)
    collist = ", ".join(f"`{c}`" for c in cols)
    # Idempotent: clear any partial slice, then copy the full prior-day slice from gold.
    execute_sql(w, sql_text=f"DELETE FROM {MIG} WHERE DateID={bdid}", warehouse_id=wid, poll_deadline_sec=1800.0)
    execute_sql(
        w,
        sql_text=f"INSERT INTO {MIG} ({collist}) SELECT {collist} FROM {GOLD} WHERE DateID={bdid}",
        warehouse_id=wid,
        poll_deadline_sec=3600.0,
    )
    result["mig_rows_after"] = _count(w, wid, MIG, bdid)
    result["refreshed"] = True
    result["action"] = "refreshed_from_gold"
    return result


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target-date", required=True, help="block run date (YYYY-MM-DD); prior day is topped up")
    args = ap.parse_args()
    print(json.dumps(ensure_prior_day_liabilities(args.target_date), default=str, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
