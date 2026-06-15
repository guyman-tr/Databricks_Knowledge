"""
StakingLagOneMonth UC backfill — one-time fix for 3 affected month-end day-rows.

CONTEXT
-------
Daily Synapse → UC import COPIES Synapse fact rows on the day they're written.
It does not RE-EVALUATE Synapse rows when Synapse re-runs them retroactively.

Staking distributions happen in two passes:
  1. First pass (e.g. 2026-03-07): full attempted distribution, ~$1.6M.
  2. Some allocations fail airdrops; ~2 days later (e.g. 2026-03-09), a 2nd pass
     re-runs as compensations. Synapse SP STEP 3 then BACKDATES the first row
     (Apr-7, the +1-month lag of 03-07) DOWN from $1.6M to $191k, with the
     ~$1.4M difference appearing as a new Apr-9 row (+1-month lag of 03-09).

The Synapse re-run that does the backdate happens ~3 weeks later
(`UpdateDate = 2026-05-01` for the March cohort, `2026-06-01` for April,
`2026-06-10` for May).

UC's mirror was COPIED on the day Synapse first wrote the inflated value
(Apr-8, May-5, Jun-3) and never re-copied after Synapse backdated. So UC
sits at the inflated pre-comp value for 3 specific days:

   DateID    UC sum (wrong)        Syn sum (correct)    Δ
   20260407  $1,605,711.62         $   191,834.24       +$1,413,877.39
   20260504  $1,544,047.98         $   187,973.97       +$1,356,074.00
   20260602  $1,637,984.14         $   192,939.84       +$1,445,044.30

The COMPLEMENTARY pre-backdated rows (Apr-9, May-6, Jun-4) are already correct
in UC because they were written after Synapse's backdating completed.

SCOPE
-----
- ONLY the 3 specific DateIDs: 20260407, 20260504, 20260602.
- ONLY rows WHERE `Metric = 'StakingLagOneMonth'`.
- Apr-9, May-6, Jun-4 rows are LEFT UNTOUCHED (already correct).
- All other Staking* metrics are LEFT UNTOUCHED.

TRUTH SOURCE
------------
The diagnostic confirmed that UC `main.etoro_kpi_prep.v_revenue_stakingfee`
already reflects the post-backdate state (it reads from the same
`Dealing_Staking_Results` table Synapse uses) and produces byte-identical output
to Synapse's `Function_Revenue_StakingFee` TVF.

We build the staging table by replicating the UC SP STEP 3 INSERT logic
against `v_revenue_stakingfee` for the 3 source-month windows that map to the
3 affected DateIDs. This is purely-UC, single-statement, and seconds-fast —
no need to stream 1.38M rows through pyodbc.

A post-stage cross-check confirms staging matches Synapse fact penny-for-penny
before any DELETE/INSERT touches the gold target.

EXECUTION FLOW
--------------
1. Build staging from `v_revenue_stakingfee` (one INSERT per source-month).
2. Cross-check staging vs Synapse fact: row counts and sum_amt per DateID.
3. DELETE existing StakingLagOneMonth rows in UC target for the 3 DateIDs.
4. INSERT FROM staging into target.
5. Post-fix verification: target now matches Synapse for the 3 DateIDs.

USAGE
-----
    python proposals/staking_lag_one_month_backfill_2026_06/backfill_staking_lag.py --dry-run
    python proposals/staking_lag_one_month_backfill_2026_06/backfill_staking_lag.py --apply
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
AFFECTED_DATEIDS = [20260407, 20260504, 20260602]  # first-pass rows that need backdating
DATEIDS_SQL_LIST = ", ".join(str(d) for d in AFFECTED_DATEIDS)

# Source-month windows in v_revenue_stakingfee that map to each affected DateID
# via DATEADD(MONTH, 1, source_date). The view groups by source DateID, so a
# WHERE BETWEEN month-start AND month-end on the source side captures both
# the first-pass row AND the comp-pass row — but we filter by `paid_date_id IN
# AFFECTED_DATEIDS` after the +1-month shift, which keeps only the first-pass
# row (Apr-7 from Mar-7, May-4 from Apr-4, Jun-2 from May-2).
SOURCE_WINDOWS = [
    # (source_from, source_to)  — covers the entire source month
    (20260301, 20260331),  # March 2026 → paid in April
    (20260401, 20260430),  # April 2026 → paid in May
    (20260501, 20260531),  # May 2026   → paid in June
]

TARGET_TABLE = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
STAGING_TABLE = (
    "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
    "__staking_lag_backfill_20260610"
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
# Step 1 — build staging from v_revenue_stakingfee
# ---------------------------------------------------------------------------
def synapse_summary():
    """Cross-check reference: per-DateID summary of Synapse fact for the affected DateIDs."""
    sql = f"""
SELECT DateID, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'StakingLagOneMonth'
  AND DateID IN ({DATEIDS_SQL_LIST})
GROUP BY DateID
ORDER BY DateID
"""
    res = synapse.run(sql)
    return {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}


def create_staging_table(w: WorkspaceClient):
    print(f"[1/5] (Re)creating staging table {STAGING_TABLE}...")
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
COMMENT 'One-time StakingLagOneMonth backfill staging — DateIDs 20260407/20260504/20260602. See proposals/staking_lag_one_month_backfill_2026_06.'
"""
    run_sql(w, ddl)
    print(f"      created.")


def build_staging_from_view(w: WorkspaceClient):
    """Replicate UC SP STEP 3 INSERT logic for the 3 source-month windows.

    Filters at the END to keep ONLY first-pass rows (Apr-7, May-4, Jun-2) —
    the comp-pass rows (Apr-9, May-6, Jun-4) are already correct in UC and
    are explicitly excluded from staging via the `IN AFFECTED_DATEIDS` filter.
    """
    cols = ", ".join(COLUMN_LIST)
    union_legs = []
    for src_from, src_to in SOURCE_WINDOWS:
        union_legs.append(f"""
SELECT * FROM (
    SELECT
        CAST(DATE_FORMAT(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1), 'yyyyMMdd') AS INT) AS DateID,
        CAST(ADD_MONTHS(to_date(CAST(s.DateID AS STRING), 'yyyyMMdd'), 1) AS TIMESTAMP)             AS Date,
        CAST(s.CID AS INT)                                                                          AS RealCID,
        CAST(NULL AS INT)                                                                           AS ActionTypeID,
        'Staking'                                                                                   AS ActionType,
        10                                                                                          AS InstrumentTypeID,
        1                                                                                           AS IsSettled,
        CAST(NULL AS INT)                                                                           AS IsCopy,
        'StakingLagOneMonth'                                                                        AS Metric,
        CAST(SUM(s.TotalUSDDistributed) AS DECIMAL(16,6))                                           AS Amount,
        0                                                                                           AS CountTransactions,
        1                                                                                           AS IncludedInTotalRevenue,
        0                                                                                           AS CountAsActiveTrade,
        current_timestamp()                                                                         AS UpdateDate,
        1                                                                                           AS IsBuy,
        0                                                                                           AS IsLeveraged,
        0                                                                                           AS IsFuture,
        0                                                                                           AS IsCopyFund,
        CAST(NULL AS INT)                                                                           AS IsOpenedFromIBAN,
        CAST(NULL AS INT)                                                                           AS IsClosedToIBAN,
        CAST(NULL AS INT)                                                                           AS IsRecurring,
        CAST(NULL AS INT)                                                                           AS IsAirDrop,
        CAST(NULL AS INT)                                                                           AS IsSQF,
        12                                                                                          AS RevenueMetricID,
        4                                                                                           AS RevenueMetricCategoryID,
        CAST(NULL AS INT)                                                                           AS IsMarginTrade,
        CAST(NULL AS INT)                                                                           AS IsC2P
    FROM main.etoro_kpi_prep.v_revenue_stakingfee s
    WHERE s.DateID BETWEEN {src_from} AND {src_to}
    GROUP BY s.CID, s.DateID
) t
WHERE t.DateID IN ({DATEIDS_SQL_LIST})
""")
    union_sql = "\nUNION ALL\n".join(union_legs)

    full_sql = f"INSERT INTO {STAGING_TABLE} ({cols})\n{union_sql}"

    print(f"[2/5] Building staging via single SQL from main.etoro_kpi_prep.v_revenue_stakingfee...")
    t0 = time.time()
    run_sql(w, full_sql)
    print(f"      built in {time.time()-t0:.1f}s.")


def staging_summary(w: WorkspaceClient):
    res = run_sql(w, f"""
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {STAGING_TABLE}
GROUP BY DateID
ORDER BY DateID
""")
    return {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}


def sanity_check(w: WorkspaceClient) -> bool:
    print(f"[3/5] Cross-checking staging vs Synapse fact (truth-of-truth comparison)...")
    syn = synapse_summary()
    stg = staging_summary(w)
    if sorted(syn) != sorted(stg):
        print(f"      FAIL: day sets differ.")
        print(f"      syn-only: {sorted(set(syn) - set(stg))}")
        print(f"      stg-only: {sorted(set(stg) - set(syn))}")
        return False
    fails = 0
    print(f"      {'DateID':<10} {'syn_rows':>8} {'syn_sum':>14} {'stg_rows':>8} {'stg_sum':>14} status")
    for d in sorted(syn):
        s = syn[d]
        t = stg[d]
        ok = (s[0] == t[0]) and (abs(s[1] - t[1]) < 0.01)
        flag = "MATCH" if ok else "DIFF"
        if not ok:
            fails += 1
        print(f"      {d:<10} {s[0]:>8} {s[1]:>14.4f} {t[0]:>8} {t[1]:>14.4f} {flag}")
    if fails:
        print(f"      FAIL: {fails} day(s) differ.")
        return False
    print(f"      PASS: all {len(syn)} days match Synapse.")
    return True


# ---------------------------------------------------------------------------
# Step 4 — delete UC rows for the affected DateIDs
# ---------------------------------------------------------------------------
def delete_target_range(w: WorkspaceClient):
    print(f"[4/5] Deleting StakingLagOneMonth rows in target for DateIDs {AFFECTED_DATEIDS}...")
    res = run_sql(w, f"""
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {TARGET_TABLE}
WHERE Metric = 'StakingLagOneMonth' AND DateID IN ({DATEIDS_SQL_LIST})
GROUP BY DateID ORDER BY DateID
""")
    pre_total = 0
    pre_sum = 0.0
    for r in res.rows:
        pre_total += int(r[1])
        pre_sum += float(r[2] or 0.0)
        print(f"      pre-delete DateID={r[0]} rows={r[1]} sum={float(r[2] or 0.0):.2f}")
    print(f"      pre-delete totals: rows={pre_total} sum={pre_sum:.2f}")
    run_sql(w, f"""
DELETE FROM {TARGET_TABLE}
WHERE Metric = 'StakingLagOneMonth' AND DateID IN ({DATEIDS_SQL_LIST})
""")
    res = run_sql(w, f"""
SELECT COUNT(*) FROM {TARGET_TABLE}
WHERE Metric = 'StakingLagOneMonth' AND DateID IN ({DATEIDS_SQL_LIST})
""")
    post = int(res.rows[0][0]) if res.rows else 0
    print(f"      post-delete count: {post}")
    if post != 0:
        raise RuntimeError(f"DELETE did not clear; {post} rows remain.")


def insert_target_from_staging(w: WorkspaceClient):
    print(f"[5/5] Inserting from staging into target + post-fix verification...")
    cols = ", ".join(COLUMN_LIST)
    run_sql(w, f"""
INSERT INTO {TARGET_TABLE} ({cols})
SELECT {cols} FROM {STAGING_TABLE}
""")
    res = run_sql(w, f"""
SELECT DateID, COUNT(*), SUM(Amount) FROM {TARGET_TABLE}
WHERE Metric = 'StakingLagOneMonth' AND DateID IN ({DATEIDS_SQL_LIST})
GROUP BY DateID ORDER BY DateID
""")
    for r in res.rows:
        print(f"      target DateID={r[0]} rows={r[1]} sum={float(r[2]):.2f}")


def verify_post_fix(w: WorkspaceClient) -> bool:
    print(f"      Synapse vs UC final check for StakingLagOneMonth on {AFFECTED_DATEIDS}...")
    syn = synapse_summary()
    res = run_sql(w, f"""
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {TARGET_TABLE}
WHERE Metric = 'StakingLagOneMonth' AND DateID IN ({DATEIDS_SQL_LIST})
GROUP BY DateID
ORDER BY DateID
""")
    uc = {int(r[0]): (int(r[1]), float(r[2]) if r[2] is not None else 0.0) for r in res.rows}
    fails = 0
    for d in sorted(syn):
        s = syn[d]; u = uc.get(d)
        if not u or s[0] != u[0] or abs(s[1] - u[1]) > 0.01:
            print(f"      DateID={d} FAIL syn={s} uc={u}")
            fails += 1
        else:
            print(f"      DateID={d} OK rows={u[0]} sum={u[1]:.2f}")
    if fails == 0:
        print(f"      PASS: UC now matches Synapse for all {len(syn)} affected DateIDs.")
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
                   help="Explicit dry-run (default behaviour).")
    args = p.parse_args()

    if args.apply and args.dry_run:
        print("ERROR: --apply and --dry-run are mutually exclusive.")
        sys.exit(2)
    apply = args.apply

    print("=" * 70)
    print("StakingLagOneMonth UC backfill")
    print(f"  DateIDs:   {AFFECTED_DATEIDS}")
    print(f"  Source:    main.etoro_kpi_prep.v_revenue_stakingfee (replicates UC SP STEP 3)")
    print(f"  Cross-check: Synapse BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions")
    print(f"  Staging:   {STAGING_TABLE}")
    print(f"  Target:    {TARGET_TABLE}")
    print(f"  Mode:      {'APPLY' if apply else 'DRY-RUN (steps 1-3 only)'}")
    print(f"  NOT touched: complementary 2nd-pass rows (Apr-9, May-6, Jun-4)")
    print(f"               and any other Staking* metric rows.")
    print("=" * 70)
    print()

    w = WorkspaceClient()
    create_staging_table(w)
    build_staging_from_view(w)

    ok = sanity_check(w)
    if not ok:
        print("\nABORT: staging did not match Synapse. Inspect before applying.")
        sys.exit(1)

    if not apply:
        print(f"\nDRY-RUN complete. Re-run with --apply to perform the DELETE + INSERT.")
        print(f"Staging table left in place: {STAGING_TABLE}")
        return

    delete_target_range(w)
    insert_target_from_staging(w)

    if not verify_post_fix(w):
        print("\nABORT: post-fix verification failed.")
        sys.exit(1)

    print()
    print("=" * 70)
    print("DONE.")
    print(f"Staging table left in place for audit: {STAGING_TABLE}")
    print("=" * 70)


if __name__ == "__main__":
    main()
