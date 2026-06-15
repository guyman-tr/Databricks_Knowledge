"""
Options_PFOF UC backfill — one-time fix.

CONTEXT
-------
The UC stored procedure `de_output_stg.sp_ddr_fact_revenue_generating_actions`
has not been invoked by an orchestrator since 2026-05-01 (one-shot rerun).
STEP 2 of that SP is the only writer of `Metric = 'Options_PFOF'` rows in UC.
As a result, the gold fact table
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
is missing Options_PFOF for 48 days between 2026-03-27 and 2026-06-05.
(2026-06-08 was already populated manually during the diagnostic.)

SCOPE
-----
- This script ONLY backfills `Metric = 'Options_PFOF'` rows.
- StakingLagOneMonth (~8x overcount on 3 month-end days) is OUT OF SCOPE —
  separate ticket; needs SP STEP 3 GROUP BY investigation, not a backfill.
- TicketFee/TicketFeeByPercent rollup is BY DESIGN going forward — not a fix.

TRUTH SOURCE
------------
Synapse `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` rows for
DateID BETWEEN 20260327 AND 20260607 AND Metric = 'Options_PFOF'.

Why Synapse and not UC's `v_revenue_optionsplatform`? Both have been verified
to produce byte-identical rows for every overlapping day; using Synapse is
strictly conservative (it's the source the daily pipeline has been shipping
all year and its rows match what's live in production reports).

EXECUTION FLOW
--------------
1. Read missing rows from Synapse via pyodbc.
2. Write them to a UC staging table (verbose, dated, audit-friendly name).
3. Sanity-check: row count + sum-amount per day, staging vs Synapse source.
4. DELETE existing Options_PFOF rows in target for 20260327..20260607
   (defensive — should be zero rows, but covers any partial prior runs).
5. INSERT FROM staging into gold target.
6. Post-fix verification: re-run the day-by-day Synapse-vs-UC diff for
   Options_PFOF over the affected range and confirm zero remaining gaps.

The staging table is left in place after success for audit. Drop manually
when no longer needed.

USAGE
-----
    python proposals/options_pfof_backfill_2026_06/backfill_options_pfof.py --dry-run
    python proposals/options_pfof_backfill_2026_06/backfill_options_pfof.py --apply

`--dry-run` (default) executes steps 1-3 only (fetch + stage + sanity check).
`--apply` additionally runs steps 4-6 (delete + insert + verify).
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "eval_suite"))
sys.path.insert(0, str(REPO_ROOT / "tools" / "eval_suite" / "loop_authoring"))

import synapse  # noqa: E402
from databricks.sdk import WorkspaceClient  # noqa: E402
from dbx import run_sql  # noqa: E402


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BACKFILL_FROM = 20260327
BACKFILL_TO = 20260607  # 20260608 already populated manually, so stop at 7

TARGET_TABLE = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
STAGING_TABLE = (
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
    "__options_pfof_backfill_20260610"
)

COLUMN_LIST = [
    "DateID", "Date", "RealCID", "ActionTypeID", "ActionType", "InstrumentTypeID",
    "IsSettled", "IsCopy", "Metric", "Amount", "CountTransactions",
    "IncludedInTotalRevenue", "CountAsActiveTrade", "UpdateDate", "IsBuy",
    "IsLeveraged", "IsFuture", "IsCopyFund", "IsOpenedFromIBAN", "IsClosedToIBAN",
    "IsRecurring", "IsAirDrop", "IsSQF", "RevenueMetricID", "RevenueMetricCategoryID",
    "IsMarginTrade", "IsC2P",
]


# ---------------------------------------------------------------------------
# Step 1 — fetch from Synapse
# ---------------------------------------------------------------------------
def fetch_synapse_rows():
    sql = f"""
SELECT
    DateID, [Date], RealCID, ActionTypeID, ActionType, InstrumentTypeID,
    IsSettled, IsCopy, Metric, Amount, CountTransactions,
    IncludedInTotalRevenue, CountAsActiveTrade, UpdateDate, IsBuy,
    IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN,
    IsRecurring, IsAirDrop, IsSQF, RevenueMetricID, RevenueMetricCategoryID,
    IsMarginTrade, IsC2P
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
ORDER BY DateID, RealCID
"""
    print(f"[1/6] Fetching Options_PFOF rows from Synapse ({BACKFILL_FROM}..{BACKFILL_TO})...")
    t0 = time.time()
    res = synapse.run(sql, timeout_s=900)
    print(f"      fetched {len(res.rows)} rows in {time.time()-t0:.1f}s")
    return res.rows


def synapse_summary():
    sql = f"""
SELECT DateID, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
GROUP BY DateID
ORDER BY DateID
"""
    res = synapse.run(sql)
    return {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}


# ---------------------------------------------------------------------------
# Step 2 — stage into UC
# ---------------------------------------------------------------------------
def create_staging_table(w: WorkspaceClient):
    print(f"[2/6] (Re)creating staging table {STAGING_TABLE}...")
    run_sql(w, f"DROP TABLE IF EXISTS {STAGING_TABLE}")
    ddl = f"""
CREATE TABLE {STAGING_TABLE} (
  DateID INT, Date TIMESTAMP, RealCID INT, ActionTypeID INT, ActionType STRING,
  InstrumentTypeID INT, IsSettled INT, IsCopy INT, Metric STRING,
  Amount DECIMAL(16,6), CountTransactions INT, IncludedInTotalRevenue INT,
  CountAsActiveTrade INT, UpdateDate TIMESTAMP, IsBuy INT, IsLeveraged INT,
  IsFuture INT, IsCopyFund INT, IsOpenedFromIBAN INT, IsClosedToIBAN INT,
  IsRecurring INT, IsAirDrop INT, IsSQF INT, RevenueMetricID INT,
  RevenueMetricCategoryID INT, IsMarginTrade INT, IsC2P INT
)
USING DELTA
COMMENT 'One-time Options_PFOF backfill staging — 2026-03-27..2026-06-07. See proposals/options_pfof_backfill_2026_06.'
"""
    run_sql(w, ddl)
    print(f"      created.")


def insert_staging_rows(w: WorkspaceClient, rows):
    """Bulk-insert via VALUES batches. Keeps batches small to avoid SQL size limits."""
    if not rows:
        print("[2/6] no rows to stage; skipping.")
        return
    BATCH = 500
    print(f"[2/6] Inserting {len(rows)} rows into staging in batches of {BATCH}...")
    t0 = time.time()
    total = 0
    for i in range(0, len(rows), BATCH):
        batch = rows[i:i + BATCH]
        values_sql = ",\n".join(_row_to_values(r) for r in batch)
        sql = f"INSERT INTO {STAGING_TABLE} ({', '.join(COLUMN_LIST)}) VALUES\n{values_sql}"
        run_sql(w, sql)
        total += len(batch)
        if (i // BATCH) % 10 == 0:
            print(f"      ... {total}/{len(rows)} ({time.time()-t0:.1f}s)")
    print(f"      staged {total} rows in {time.time()-t0:.1f}s.")


def _row_to_values(row) -> str:
    """Render a single Synapse row as a UC SQL VALUES tuple. Order = COLUMN_LIST."""
    parts = []
    for v in row:
        if v is None:
            parts.append("NULL")
        elif isinstance(v, (int,)):
            parts.append(str(v))
        elif isinstance(v, float):
            parts.append(f"{v:.10f}")
        elif isinstance(v, datetime):
            parts.append(f"TIMESTAMP '{v.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}'")
        elif hasattr(v, "year") and hasattr(v, "month") and hasattr(v, "day") and not hasattr(v, "hour"):
            # date object
            parts.append(f"TIMESTAMP '{v.strftime('%Y-%m-%d')} 00:00:00.000'")
        elif isinstance(v, str):
            esc = v.replace("'", "''")
            parts.append(f"'{esc}'")
        else:
            # decimal.Decimal etc.
            parts.append(str(v))
    return "(" + ", ".join(parts) + ")"


# ---------------------------------------------------------------------------
# Step 3 — sanity check staging vs Synapse
# ---------------------------------------------------------------------------
def staging_summary(w: WorkspaceClient):
    res = run_sql(w, f"""
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {STAGING_TABLE}
GROUP BY DateID
ORDER BY DateID
""")
    return {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}


def sanity_check(w: WorkspaceClient) -> bool:
    print(f"[3/6] Sanity-checking staging vs Synapse source...")
    syn = synapse_summary()
    stg = staging_summary(w)
    syn_days = sorted(syn)
    stg_days = sorted(stg)

    if syn_days != stg_days:
        print(f"      FAIL: day sets differ.")
        print(f"      syn-only: {sorted(set(syn_days) - set(stg_days))}")
        print(f"      stg-only: {sorted(set(stg_days) - set(syn_days))}")
        return False

    bad = []
    for d in syn_days:
        s = syn[d]
        t = stg[d]
        if s[0] != t[0] or abs(s[1] - t[1]) > 0.01:
            bad.append((d, s, t))

    print(f"      {'DateID':<10} {'syn_rows':>8} {'syn_sum':>14} {'stg_rows':>8} {'stg_sum':>14} status")
    print(f"      {'-'*10} {'-'*8} {'-'*14} {'-'*8} {'-'*14} {'-'*6}")
    for d in syn_days:
        s = syn[d]
        t = stg[d]
        ok = (s[0] == t[0]) and (abs(s[1] - t[1]) < 0.01)
        flag = "MATCH" if ok else "DIFF"
        print(f"      {d:<10} {s[0]:>8} {s[1]:>14.4f} {t[0]:>8} {t[1]:>14.4f} {flag}")

    if bad:
        print(f"      FAIL: {len(bad)} day(s) differ between Synapse and staging.")
        return False
    print(f"      PASS: all {len(syn_days)} days match Synapse.")
    return True


# ---------------------------------------------------------------------------
# Step 4 — delete existing Options_PFOF rows in the target range
# Step 5 — insert staging into target
# Step 6 — verify
# ---------------------------------------------------------------------------
def delete_target_range(w: WorkspaceClient):
    print(f"[4/6] Deleting any existing Options_PFOF rows in {TARGET_TABLE} for {BACKFILL_FROM}..{BACKFILL_TO}...")
    res = run_sql(w, f"""
SELECT COUNT(*) FROM {TARGET_TABLE}
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
""")
    pre = int(res.rows[0][0]) if res.rows else 0
    print(f"      pre-delete count in target range: {pre}")
    run_sql(w, f"""
DELETE FROM {TARGET_TABLE}
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
""")
    res = run_sql(w, f"""
SELECT COUNT(*) FROM {TARGET_TABLE}
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
""")
    post = int(res.rows[0][0]) if res.rows else 0
    print(f"      post-delete count in target range: {post}")
    if post != 0:
        raise RuntimeError(f"DELETE did not clear target range; {post} rows remain.")


def insert_target_from_staging(w: WorkspaceClient):
    print(f"[5/6] Inserting from staging into {TARGET_TABLE}...")
    cols = ", ".join(COLUMN_LIST)
    run_sql(w, f"""
INSERT INTO {TARGET_TABLE} ({cols})
SELECT {cols} FROM {STAGING_TABLE}
""")
    res = run_sql(w, f"""
SELECT COUNT(*), SUM(Amount) FROM {TARGET_TABLE}
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
""")
    n, s = int(res.rows[0][0]), float(res.rows[0][1] or 0.0)
    print(f"      inserted into target: {n} rows, sum={s:.4f}")


def verify_post_fix(w: WorkspaceClient) -> bool:
    print(f"[6/6] Post-fix verification: Synapse vs UC for Options_PFOF over {BACKFILL_FROM}..{BACKFILL_TO}...")
    syn = synapse_summary()
    res = run_sql(w, f"""
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {TARGET_TABLE}
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN {BACKFILL_FROM} AND {BACKFILL_TO}
GROUP BY DateID
ORDER BY DateID
""")
    uc = {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}

    syn_days = sorted(syn)
    uc_days = sorted(uc)
    print(f"      Synapse days: {len(syn_days)}, UC days: {len(uc_days)}")

    fails = 0
    for d in syn_days:
        s = syn[d]
        u = uc.get(d)
        if u is None:
            print(f"      DateID={d} MISSING in UC")
            fails += 1
            continue
        if s[0] != u[0] or abs(s[1] - u[1]) > 0.01:
            print(f"      DateID={d} DIFF syn=({s[0]}, {s[1]:.4f}) uc=({u[0]}, {u[1]:.4f})")
            fails += 1

    if fails == 0:
        print(f"      PASS: UC now matches Synapse for all {len(syn_days)} days.")
        return True
    print(f"      FAIL: {fails} day(s) still mismatched.")
    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true",
                   help="Run all 6 steps. Without this flag, only steps 1-3 (fetch + stage + sanity) run.")
    p.add_argument("--dry-run", action="store_true",
                   help="Explicit dry-run (default behaviour). Stages and sanity-checks only.")
    args = p.parse_args()

    if args.apply and args.dry_run:
        print("ERROR: --apply and --dry-run are mutually exclusive.")
        sys.exit(2)
    apply = args.apply

    print("=" * 70)
    print("Options_PFOF UC backfill")
    print(f"  Date range: {BACKFILL_FROM} .. {BACKFILL_TO}")
    print(f"  Source:     Synapse BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions")
    print(f"  Staging:    {STAGING_TABLE}")
    print(f"  Target:     {TARGET_TABLE}")
    print(f"  Mode:       {'APPLY' if apply else 'DRY-RUN (steps 1-3 only)'}")
    print("=" * 70)
    print()

    rows = fetch_synapse_rows()

    w = WorkspaceClient()
    create_staging_table(w)
    insert_staging_rows(w, rows)

    ok = sanity_check(w)
    if not ok:
        print("\nABORT: staging did not match Synapse. Inspect staging table and fix before applying.")
        sys.exit(1)

    if not apply:
        print("\nDRY-RUN complete. Re-run with --apply to perform the DELETE + INSERT against the target.")
        print(f"Staging table left in place: {STAGING_TABLE}")
        return

    delete_target_range(w)
    insert_target_from_staging(w)

    if not verify_post_fix(w):
        print("\nABORT: post-fix verification failed. Investigate before declaring done.")
        sys.exit(1)

    print()
    print("=" * 70)
    print("DONE.")
    print(f"Staging table left in place for audit: {STAGING_TABLE}")
    print("Drop manually with:")
    print(f"  DROP TABLE {STAGING_TABLE}")
    print("=" * 70)


if __name__ == "__main__":
    main()
