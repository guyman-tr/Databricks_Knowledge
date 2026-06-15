# StakingLagOneMonth UC Backfill — One-Time Fix

**Date:** 2026-06-10
**Author:** eval-suite-v1 detour findings (after Options_PFOF backfill)
**Scope:** 3 specific day-rows where UC `Metric = 'StakingLagOneMonth'` is overstated by ~$1.4M each, totaling **+$4.21M** in cumulative misstatement.

## Background

Staking distributions happen in two passes:

1. **First pass** (e.g. 2026-03-07): full attempted distribution to all eligible CIDs, total ~$1.6M.
2. **Compensation pass** ~2 days later (e.g. 2026-03-09): allocations that failed airdrops are re-run as USD compensations.

The Synapse SP STEP 3 **backdates** the first-pass row when the comp pass arrives:

- The `+1-month` row (Apr-7 from March-7) gets DELETED and re-INSERTED with the post-comp value (~$191k — only the successful airdrops).
- A new row appears at `+1-month` from the comp date (Apr-9 from March-9) with the comp amount (~$1.4M).

The total stays the same ($191k + $1.4M = $1.6M), but it gets split across two days based on what actually paid out and when.

The Synapse SP backdate happens via a re-run several weeks later, when the post-comp `Dealing_Staking_Results` is stable. This was added explicitly in 2026-01-13 with the comment:

> "mechanism to deal with Staking reruns on the source (data changes retroactively). this change should be working both in synapse and auto-update the lake via SB."

## Why UC didn't get the backdating

Same root cause as Options_PFOF: the daily Synapse → UC import COPIES Synapse fact rows on the day they're written. It does NOT re-evaluate Synapse fact rows when Synapse rewrites them retroactively.

So:
- UC Apr-7 was copied on 2026-04-08 (`UpdateDate` stamps confirm) — back when Synapse Apr-7 still showed the pre-comp $1.6M.
- Synapse later rewrote Apr-7 down to $191k on 2026-05-01.
- UC was never re-copied — its Apr-7 stayed at $1.6M.
- The Apr-9 comp row was copied later (after the comp pass) and is correct in UC.

## The 3 affected day-rows

| DateID    | UC sum (wrong)     | Syn sum (correct)  | Δ                 | Cohort month |
|-----------|---------------------|---------------------|--------------------|--------------|
| 20260407  | $1,605,711.62       | $191,834.24         | -$1,413,877.39     | March 2026   |
| 20260504  | $1,544,047.98       | $187,973.97         | -$1,356,074.00     | April 2026   |
| 20260602  | $1,637,984.14       | $192,939.84         | -$1,445,044.30     | May 2026     |
| **TOTAL** | **$4,787,743.74**   | **$572,748.05**     | **-$4,214,995.69** |              |

The complementary comp-pass rows (Apr-9, May-6, Jun-4) are **already correct** in UC and are NOT touched by this fix.

## What this script does

Identical pattern to `proposals/options_pfof_backfill_2026_06/backfill_options_pfof.py`:

1. Read corrected rows from Synapse for the 3 affected DateIDs.
2. Stage to UC table:
   `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions__staking_lag_backfill_20260610`
3. Sanity-check staging vs Synapse.
4. `DELETE` existing StakingLagOneMonth rows in target for the 3 DateIDs.
5. `INSERT FROM` staging into target.
6. Post-fix verification.

The staging table is left in place after success for audit; drop manually when no longer needed.

## Usage

```
# Dry run: fetches from Synapse, stages into UC, sanity-checks. No changes to target.
python proposals/staking_lag_one_month_backfill_2026_06/backfill_staking_lag.py --dry-run

# Apply: same as above PLUS DELETE + INSERT into target + post-fix verify.
python proposals/staking_lag_one_month_backfill_2026_06/backfill_staking_lag.py --apply
```

## Expected output volume

- **3 day-rows** in the fact table will be replaced.
- **~1.38M source rows** flowing through (460,055 + 460,982 + 459,826 CIDs across the 3 first-pass dates).
- This will take noticeably longer than Options_PFOF because of the row count.

## Ground truth verified by 3 independent methods

The diagnostic confirmed all three of these produce identical output for these dates:

1. Synapse fact table (used here)
2. Synapse `Function_Revenue_StakingFee` TVF
3. UC `main.etoro_kpi_prep.v_revenue_stakingfee` view

So the fix is unambiguous.

## What this fix does NOT address

- **Re-arming the orchestrator** so the UC SP `de_output_stg.sp_ddr_fact_revenue_generating_actions` runs daily — this gap will reopen with the next staking comp pass if the SP isn't scheduled.
- **The pre-Mar-26 history** — verified clean. Daily Synapse-import was working then because there hadn't yet been a retroactive backdating event for those cohorts.
- **Other metrics** — Options_PFOF was already addressed in `proposals/options_pfof_backfill_2026_06/`. All other 15 metrics in the fact table are clean.
