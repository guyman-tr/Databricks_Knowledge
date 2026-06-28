#!/usr/bin/env python3
"""Backfill Fact_FirstCustomerAction from Synapse for the 6 months with mirror gaps.

Root cause (diagnosed 2026-06-23):
  The gold UC mirror of Fact_FirstCustomerAction is ~314k rows short of Synapse,
  concentrated in 6 months (2022-08, 2022-09, 2022-11, 2023-01, 2023-09, 2024-01).
  Those missing rows are first-ever (ActionTypeID, GCID) records that Synapse captured
  historically but the mirror never replicated.

  Because migration seeds its FFCA baseline from the incomplete gold mirror, those
  combos appear "unprocessed" every time those GCIDs have new daily FCA actions —
  causing ~800+ spurious FE=0 inserts in the daily proc every day.

  The production Synapse SP is identical to migration's. No hidden filter. The only
  fix needed is a complete baseline.

Fix:
  For each of the 6 gap months: DELETE migration's FFCA rows for that month, then
  re-INSERT all rows from Synapse for that month. Ensures exact parity for those
  months and closes the baseline gap.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

try:
    from synapse_connect import connect as synapse_connect, run_query as synapse_run_query
except ImportError:
    synapse_connect = None  # type: ignore[assignment]
    synapse_run_query = None  # type: ignore[assignment]

TGT = "dwh_daily_process.migration_tables.Fact_FirstCustomerAction"

COLS = (
    "GCID,RealCID,DemoCID,FirstOccurred,IPNumber,IsReal,ActionTypeID,PlatformTypeID,"
    "InstrumentID,Amount,PositionID,CampaignID,BonusTypeID,FundingTypeID,LoginID,MirrorID,"
    "WithdrawID,PostID,CaseID,DateID,TimeID,CompensationReasonID,WithdrawPaymentID,"
    "DepositID,HistoryID,FirstEver,UpdateDate"
)

# Months with confirmed mirror gaps (Synapse vs gold mirror diff > 0)
GAP_MONTHS = [
    (202208, 20220801, 20220831),
    (202209, 20220901, 20220930),
    (202211, 20221101, 20221130),
    (202301, 20230101, 20230131),
    (202302, 20230201, 20230228),  # only 6 missing, included for completeness
    (202309, 20230901, 20230930),
    (202401, 20240101, 20240131),
]


def _sql_literal(v: object) -> str:
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("'", "''")
    return f"'{s}'"


def resync_month(w, wid, ym: int, date_from: int, date_to: int, dry_run: bool) -> None:
    print(f"\n--- {ym} (DateID {date_from}–{date_to}) ---", flush=True)

    conn = synapse_connect(verbose=False)
    try:
        _, rows = synapse_run_query(
            conn,
            f"SELECT {COLS} FROM DWH_dbo.Fact_FirstCustomerAction "
            f"WHERE DateID BETWEEN {date_from} AND {date_to}",
        )
    finally:
        conn.close()

    print(f"  Synapse: {len(rows):,} rows", flush=True)

    if dry_run:
        print(f"  [DRY RUN] would DELETE+INSERT {len(rows):,} rows for {ym}")
        return

    # Delete migration rows for this month
    execute_sql(
        w,
        sql_text=f"DELETE FROM {TGT} WHERE DateID BETWEEN {date_from} AND {date_to}",
        warehouse_id=wid,
        poll_deadline_sec=600.0,
    )
    print(f"  Deleted migration rows for DateID {date_from}–{date_to}", flush=True)

    # Insert Synapse rows in chunks
    col_list = COLS.replace(" ", "")
    chunk_size = 5000
    inserted = 0
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i : i + chunk_size]
        values = [f"({', '.join(_sql_literal(v) for v in r)})" for r in chunk]
        sql = f"INSERT INTO {TGT} ({col_list}) VALUES " + ", ".join(values)
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        inserted += len(chunk)
        if inserted % 50000 < chunk_size:
            print(f"  inserted {inserted:,}/{len(rows):,}", flush=True)

    print(f"  Done — {inserted:,} rows for {ym}", flush=True)


def main() -> int:
    ap = argparse.ArgumentParser(description="Resync FFCA gap months from Synapse into migration table.")
    ap.add_argument("--apply", action="store_true", help="Actually delete+insert; default is dry run.")
    ap.add_argument("--month", type=int, help="Only process one specific YYYYMM (optional).")
    args = ap.parse_args()

    if synapse_connect is None:
        print("ERROR: synapse_connect module not available — cannot reach Synapse")
        return 1

    w = make_workspace_client()
    wid = warehouse_id_from_env()

    months = GAP_MONTHS
    if args.month:
        months = [(ym, d_from, d_to) for ym, d_from, d_to in GAP_MONTHS if ym == args.month]
        if not months:
            print(f"ERROR: {args.month} not in the gap-month list: {[x[0] for x in GAP_MONTHS]}")
            return 1

    for ym, d_from, d_to in months:
        resync_month(w, wid, ym, d_from, d_to, dry_run=not args.apply)

    print("\nAll gap months processed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
