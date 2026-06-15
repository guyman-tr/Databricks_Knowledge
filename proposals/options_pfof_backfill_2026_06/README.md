# Options_PFOF UC Backfill — One-Time Fix

**Date:** 2026-06-10
**Author:** eval-suite-v1 detour findings
**Scope:** `Metric = 'Options_PFOF'` rows missing in UC fact table for 48 days between **2026-03-27 and 2026-06-05**.

## Background

While building the eval-suite ground-truth for DDR tile #1 (Revenue: Totals, 2026-06-08), we found a $1,334.57 gap between Synapse `Function_DDR_Aggregation_Yesterday` and the UC equivalent. 100% of the gap was `Options_PFOF` rows present in Synapse but missing in UC.

A full Jan-1-onwards day-by-day diff of the entire `BI_DB_DDR_Fact_Revenue_Generating_Actions` revealed:

- **13 of 17 metrics are clean** — daily Synapse-import is doing its job for those.
- **Options_PFOF** is broken from 2026-03-27 onwards. The UC stored procedure `de_output_stg.sp_ddr_fact_revenue_generating_actions` STEP 2 (the only writer of `Options_PFOF` into UC) has not been invoked by an orchestrator since a one-shot rerun on 2026-05-01 (which only landed Apr-28 data).
- StakingLagOneMonth has a separate ~8x overcount issue on 3 month-end days — **not addressed here**, separate ticket.
- TicketFee/TicketFeeByPercent UC rollup is by design going forward — **not a fix**.

Full diagnostic in `audits/eval_suite/`:
- `options_pfof_root_cause.md`
- `pfof_since_jan.csv`
- `all_metrics_since_jan.csv`
- `all_metrics_since_jan_summary.csv`
- `diff_metrics_drilldown.txt`

## What this script does

1. Reads `Options_PFOF` rows from Synapse for `DateID BETWEEN 20260327 AND 20260607` (Jun-8 was already manually inserted during the diagnostic).
2. Writes them to a UC staging table:
   `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions__options_pfof_backfill_20260610`
3. Sanity-checks staging vs Synapse: row count + sum-amount per day must match exactly.
4. `DELETE` any existing Options_PFOF rows in the target range (defensive — should be zero).
5. `INSERT` from staging into the gold target.
6. Post-fix verification: re-run the per-day Synapse-vs-UC diff for the affected range; confirm zero remaining gaps.

The staging table is left in place after success for audit; drop manually when no longer needed.

## Why Synapse as the truth source

Both Synapse `BI_DB_dbo.Function_Revenue_OptionsPlatform` and UC `main.etoro_kpi_prep.v_revenue_optionsplatform` were verified to produce byte-identical rows for every overlapping day. Either source would work.

Synapse is the more conservative choice because (a) it's been the daily-shipping source-of-truth for everything else all year, (b) the rows we're copying are *literally the same rows* that flow into the production reports today, and (c) it avoids any dependency on UC's view layer behaving identically (we know it does, but Synapse rules out one more layer of risk).

## Usage

```
# Dry run: fetches from Synapse, stages into UC, sanity-checks. No changes to target.
python proposals/options_pfof_backfill_2026_06/backfill_options_pfof.py --dry-run

# Apply: same as above PLUS DELETE + INSERT into target + post-fix verify.
python proposals/options_pfof_backfill_2026_06/backfill_options_pfof.py --apply
```

Run from repo root. Requires Synapse credentials (`~/.cursor/synapse-credentials.env`) and Databricks CLI auth (same as `tools/dbx_query.py`).

## Expected output volume

- **48 days** to backfill.
- **~17,000 rows** total (~360 rows/day average).
- **~$48k** in `Amount` summed across the range.

## Out of scope

- **StakingLagOneMonth** ~8x overcount on 2026-04-07, 2026-05-04, 2026-06-02. The UC SP STEP 3 produces ~8.3x the correct value. Needs SP investigation, not a backfill — the SP body's GROUP BY appears to drop a key. Tracked separately.
- **Re-arming the orchestrator** so the UC SP runs daily. Out of scope for this fix; needs Lakeflow / job-wiring change.
- **TicketFee / TicketFeeByPercent rollup** — by design going forward, no action.
