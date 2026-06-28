#!/usr/bin/env python3
"""POC-only side repair: bootstrap a valid prior-day baseline for fact_snapshotequity.

This is NOT part of the production job. In production, the prior-day snapshot already
lives in the migration schema (the daily process runs incrementally). In this POC the
migration table was restored from a time-travel baseline whose prior-day rows are
corrupt (zero sums), so the incremental core SP carries forward garbage.

This module detects that gap and, only when needed, seeds the prior-day baseline from
gold so the clean job can "proceed as if the data was there all along".
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

GOLD = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid"
MIG = "dwh_daily_process.migration_tables.fact_snapshotequity"

# 26 columns present in both gold and migration.
COMMON_COLS = [
    "CID", "DateRangeID", "TotalPositionsAmount", "TotalCash", "InProcessCashouts",
    "TotalMirrorPositionsAmount", "TotalMirrorCash", "TotalStockOrders", "TotalMirrorStockOrders",
    "RealizedEquity", "Credit", "AUM", "BonusCredit", "CreditID", "UpdateDate",
    "TotalStockPositionAmount", "TotalMirrorStockPositionAmount",
    "TotalCryptoPositionAmount", "TotalMirrorCryptoPositionAmount",
    "TotalRealStocks", "TotalRealCrypto", "TotalRealCryptoLoan", "TotalCashCalculation",
    "TotalCryptoPositionAmount_TRS", "TotalMirrorCryptoPositionAmount_TRS", "Total_TRSCrypto",
]
# 6 columns that exist only in migration -> zero-filled (gold has no source for them).
ZERO_FILL_COLS = [
    "TotalMirrorRealFuturesPositionAmount", "TotalRealFutures", "TotalFuturesProviderMargin",
    "TotalFuturesLockedCash", "TotalStocksMargin", "TotalStockMarginLoanValue",
]


def _target_date(arg: str | None) -> dt.date:
    if arg:
        return dt.date.fromisoformat(arg)
    return dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)


def _open_drid(day: dt.date) -> int:
    """Open-snapshot DateRangeID for a day: fromdate(8) + year-end suffix '1231'."""
    return int(day.strftime("%Y%m%d") + "1231")


def _drid_stats(w, wid: str, table: str, drid: int) -> tuple[int, float]:
    sql = (
        f"SELECT COUNT(*) AS rows, "
        f"COALESCE(SUM(CAST(COALESCE(TotalPositionsAmount,0) AS DECIMAL(38,10))),0) AS sum_tp "
        f"FROM {table} WHERE DateRangeID = {drid}"
    )
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    r = rows[0]
    return int(r[cols.index("rows")] or 0), float(r[cols.index("sum_tp")] or 0)


def ensure_prior_day_baseline(*, target_date: dt.date, apply: bool) -> dict:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    prior = target_date - dt.timedelta(days=1)
    prior_drid = _open_drid(prior)

    gold_rows, gold_sum = _drid_stats(w, wid, GOLD, prior_drid)
    mig_rows, mig_sum = _drid_stats(w, wid, MIG, prior_drid)

    # Baseline is invalid if gold has the open snapshot but migration doesn't match it.
    needed = gold_rows > 0 and (mig_rows != gold_rows or (gold_sum != 0 and mig_sum == 0))

    result = {
        "target_date": target_date.isoformat(),
        "prior_day": prior.isoformat(),
        "prior_open_drid": prior_drid,
        "gold_prior_rows": gold_rows,
        "gold_prior_sum": gold_sum,
        "mig_prior_rows_before": mig_rows,
        "mig_prior_sum_before": mig_sum,
        "reseed_needed": needed,
        "reseed_applied": False,
    }

    if not needed or not apply:
        return result

    execute_sql(
        w,
        sql_text=f"DELETE FROM {MIG} WHERE DateRangeID = {prior_drid}",
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )

    insert_cols = COMMON_COLS + ZERO_FILL_COLS
    select_common = ", ".join(f"g.{c}" for c in COMMON_COLS)
    select_zero = ", ".join(f"CAST(0 AS DECIMAL(38,10)) AS {c}" for c in ZERO_FILL_COLS)
    execute_sql(
        w,
        sql_text=(
            f"INSERT INTO {MIG} ({', '.join(insert_cols)}) "
            f"SELECT {select_common}, {select_zero} "
            f"FROM {GOLD} g WHERE g.DateRangeID = {prior_drid}"
        ),
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )

    mig_rows_after, mig_sum_after = _drid_stats(w, wid, MIG, prior_drid)
    result["reseed_applied"] = True
    result["mig_prior_rows_after"] = mig_rows_after
    result["mig_prior_sum_after"] = mig_sum_after
    return result


def purge_corrupt_rows(*, apply: bool) -> dict:
    """Remove malformed DateRangeID rows left by earlier buggy POC runs.

    A valid DateRangeID is always 12 digits (FromDateID(8) + suffix(4)). Earlier runs
    that did numeric `+` instead of string `||` produced 8-digit garbage (e.g. 20261852).
    These rows are inert for value computation but they SHADOW their CIDs in the MERGE:
    a source CID that matches only a garbage target row takes the WHEN MATCHED path,
    fails the 'open' predicate, and is therefore never inserted via WHEN NOT MATCHED --
    so the CID silently drops out of the target day. In production this corruption never
    exists, so purging it is legitimate POC repair."""
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(
        w,
        sql_text=(
            f"SELECT COUNT(*) FROM {MIG} WHERE LENGTH(CAST(DateRangeID AS STRING)) <> 12"
        ),
        warehouse_id=wid,
    )
    bad = int(rows[0][0] or 0)
    result = {"corrupt_rows_before": bad, "purged": False}
    if bad > 0 and apply:
        execute_sql(
            w,
            sql_text=f"DELETE FROM {MIG} WHERE LENGTH(CAST(DateRangeID AS STRING)) <> 12",
            warehouse_id=wid,
            poll_deadline_sec=1800.0,
        )
        result["purged"] = True
    return result


def clear_target_day_pollution(*, target_date: dt.date, apply: bool) -> dict:
    """Remove pre-existing target-day rows in the migration table.

    The core SP is an incremental, non-idempotent MERGE: it appends a new open
    snapshot for the target day. In production the target day never pre-exists
    before that day's single run. In this POC we have re-run the job many times,
    leaving partial/garbage target-day rows that corrupt the delta. Clearing them
    reproduces the production precondition (a fresh target day)."""
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    target8 = target_date.strftime("%Y%m%d")

    def _left8_count() -> int:
        cols, rows = execute_sql(
            w,
            sql_text=(
                f"SELECT COUNT(*) AS rows FROM {MIG} "
                f"WHERE LEFT(CAST(DateRangeID AS STRING),8) = '{target8}'"
            ),
            warehouse_id=wid,
        )
        return int(rows[0][0] or 0)

    rows_before = _left8_count()
    result = {"target8": target8, "target_rows_before": rows_before, "cleared": False}
    if rows_before > 0 and apply:
        execute_sql(
            w,
            sql_text=f"DELETE FROM {MIG} WHERE LEFT(CAST(DateRangeID AS STRING),8) = '{target8}'",
            warehouse_id=wid,
            poll_deadline_sec=1800.0,
        )
        result["cleared"] = True
        result["target_rows_after"] = _left8_count()
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD; default = yesterday UTC.")
    ap.add_argument("--apply", action="store_true", help="Apply the reseed when needed (otherwise detect only).")
    args = ap.parse_args()

    report = ensure_prior_day_baseline(target_date=_target_date(args.target_date.strip() or None), apply=args.apply)
    print(json.dumps(report, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
