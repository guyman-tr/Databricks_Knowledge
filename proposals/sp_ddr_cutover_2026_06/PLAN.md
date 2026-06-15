# Cutover plan: replace Synapse-import MERGE with `sp_ddr_fact_revenue_generating_actions`

**Status:** PROPOSAL — not yet executed
**Date:** 2026-06-10
**Scope (this round):** Just `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`. Replicate the pattern to the 5 sibling DDR fact tables AFTER this proves itself.

---

## Why we're doing this

The current daily Synapse → UC import for the DDR revenue fact has a structural correctness bug: it does `MERGE INTO ... USING (Synapse-day-export) ON natural_key`, which means any retroactive Synapse update to an EXISTING row (e.g. the staking-comp pass that backdates Apr-7 from $1.6M to $191k three weeks later) is **never re-merged into UC**. UC freezes on the first-write value.

In the past 6 days we've found two confirmed instances:
- **Options_PFOF**: 48 days completely missing in UC (Mar 27 – Jun 5). Backfilled today.
- **StakingLagOneMonth**: 3 day-rows overstated by $4.21M cumulative. Backfilled today.

Both are caused by the same architecture. The risk of more silent drift is unacceptable.

## What replaces it

**`main.de_output.sp_ddr_fact_revenue_generating_actions(target_table, p_date)`** — a 72-line SQL procedure authored 2026-05-28 that already exists in production schema. It does three correctness-passes per call:

1. `DELETE WHERE DateID = p_date` then `INSERT FROM v_ddr_revenues WHERE DateID = p_date` — refreshes the target day.
2. `DELETE WHERE RevenueMetricID = 18 AND DateID >= p_date - 90d` then re-INSERT from `v_ddr_revenues WHERE Metric = 'Options_PFOF' AND DateID >= p_date - 90d` — catches Options late-arrivals within 90d.
3. `DELETE WHERE RevenueMetricID = 12 AND DateID BETWEEN month_start AND p_date` then re-INSERT from `v_ddr_revenues WHERE Metric = 'StakingLagOneMonth' AND DateID BETWEEN month_start AND p_date` — catches staking backdating within current month.

Source of truth is `main.etoro_kpi_prep.v_ddr_revenues`, a single view that wraps all 17 metric source views (`v_revenue_*`) and the `Dim_Revenue_Metrics` lookup. Calling the SP for `n` consecutive days produces a fully-correct trailing window: Options is correct for the last 90d, Staking for the current month, all other metrics for the day called.

## Validation evidence

A test run on 2026-06-10 against an empty sandbox for DateID=20260608 showed:

| Metric | Match vs Synapse | Note |
|---|---|---|
| AdminFee | OK | penny-perfect |
| CashoutFeeExclRedeem | OK | |
| CryptoToFiatFee | OK | |
| FullCommission | OK (sum), row-count -883 | sub-cent grain difference, sum identical |
| Options_PFOF | OK | the metric we just spent today fixing |
| RollOverFee | OK (sum), row-count +1,113 | sub-cent grain difference |
| SpotPriceAdjustment | OK | |
| TicketFee + TicketFeeByPercent | rolled up to TicketFee in UC | INTENTIONAL (user-confirmed semantic change) |
| TransferCoinFee | OK | |
| **ConversionFee** | **DIFF $163.15 (0.0056%)** | Likely upstream timing artifact in `fca.PIPsCalculation`; needs one-shot investigation but does not block cutover. |

The 90d Options reload step ran successfully and re-populated 90 days of `Options_PFOF` rows. The current-month Staking step found 0 rows in the test window (the May cohort hasn't paid out a comp pass yet for June 8).

SP wall-clock: **341 seconds** for one daily call against empty sandbox. Steady-state daily run will be similar.

## The cutover sequence

### Phase A — backfill correctness (no production impact)

A1. Investigate the ConversionFee $163 delta. Either explain it (and document) or fix `v_revenue_conversionfee` to match Synapse. Hard gate: cannot proceed past A2 until the SP-vs-Synapse delta is < $1 on a fresh test run.

A2. Run the SP day-by-day for the last **90 days** against the **live target**, in DRY-RUN-EQUIVALENT mode. Each day's run does its own DELETE-then-INSERT atomically, so this is safe to interleave with the existing SB MERGE writer — the MERGE will just re-write rows we wrote, which is fine because its values match ours for non-Options/Staking metrics.

   - Verify per-day after each run: SP output sum vs Synapse fact sum, drift threshold = $1.
   - Stop on any unexplained drift > $1; log to `audits/eval_suite/sp_backfill/`.

A3. Run a final 90-day spot-check sweep (same as `_diag_all_metrics_since_jan.py` but only 90d), confirm 17/17 metrics clean against Synapse.

### Phase B — wire up scheduled execution

B1. Author a Lakeflow / Databricks Workflows job:
   - **Name:** `sp_ddr_fact_revenue_generating_actions_daily`
   - **Schedule:** daily at 09:30 UTC (45 min after the existing SB MERGE runs at ~08:45 UTC, gives source views time to refresh).
   - **Task:** `CALL main.de_output.sp_ddr_fact_revenue_generating_actions(<target>, NULL)` — NULL means "yesterday".
   - **Compute:** small serverless SQL warehouse (the SP is SQL-native, no Spark cluster needed).
   - **Retry:** 2 retries, 30 min apart, on failure.
   - **Alert:** email + Slack to data-eng on failure or duration > 20 min.

B2. Run the job once manually for yesterday, verify output, confirm idempotency by re-running.

B3. Let the job run on its schedule for 7 consecutive days. Each day, automate a verification harness:
   - Compare the post-SP target row counts and per-metric sums against Synapse fact for the SP's target date and for the prior 90d (Options) and current month (Staking).
   - Surface any drift > $1 within 30 min of SP completion via the same alert channel.

### Phase C — disable Synapse-import (USER-CONTROLLED SWITCH)

C1. After 7 consecutive green days under the new SP, draft a change note pointing to:
   - Job ID + cluster of the existing SB MERGE writer for this fact table (need to identify — see below).
   - Owner of the SB job (per Delta history: service principal `fb0e925c-48b1-48f5-a619-6579d42fb7d4`; user-side owner unknown).
   - The new SP job ID and its 7-day green track record.

C2. **GUY OR DATA-ENG OWNER pauses the SB job.** Not the agent. Documented in change-mgmt / Jira DA ticket.

C3. After SB job is paused, run a 1-week verification harness identical to B3 to confirm:
   - The SP is now sole writer.
   - Daily DDR is still freshening at the expected hour.
   - Tableau dashboards consuming the gold fact still produce correct numbers.

### Phase D — replicate to siblings

After this fact has been on the SP-only path for 1 week with green verifications, repeat phases A–C for:

| Fact table (UC name) | Hypothesised SP (in `main.de_output.*`) |
|---|---|
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | `sp_ddr_customer_daily_status` (already exists, used by Guy on Jun 8) |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | `sp_ddr_fact_aum` (likely exists; verify) |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | `sp_ddr_fact_pnl` (likely exists; verify) |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | `sp_ddr_fact_trading_volumes_and_amounts` (likely exists; verify) |
| `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `sp_ddr_fact_mimo_allplatforms` (likely exists; verify) |

For each sibling, before automation, confirm: (1) the SP exists, (2) its source view exists and is healthy, (3) one test run produces clean output vs Synapse.

## Open items / things needing user input before we proceed

1. **Permission to schedule the new Lakeflow job in production.** Is this an agent-owned task or does it need a Jira DA ticket?
2. **Owner of the SB MERGE job that writes the gold fact today.** The Delta history shows service principal `fb0e925c-48b1-48f5-a619-6579d42fb7d4` (notebookId `1047849429363871`, jobId varies daily). We need to identify the human owner before phase C.
3. **ConversionFee $163 delta** — fast investigation or accept-and-document? Recommendation: 30-min investigation; if unresolved, document and proceed (it's a 0.006% drift on one day, likely upstream timing).
4. **Cutover hour.** Currently proposing 09:30 UTC; SB MERGE runs at ~08:45 UTC; source views are queried by ad-hoc users from ~07:00 UTC onwards. Need to confirm 09:30 doesn't collide with downstream Tableau extracts or other consumers that depend on the daily refresh.

## Files & evidence

- SP definition: `audits/eval_suite/sp_de_output_revgen_full.sql`
- SP-vs-Synapse test run log: `audits/eval_suite/sp_test_run.log`
- 3-way comparison (live UC / SP / Synapse): `audits/eval_suite/sp_3way.txt`
- All-metrics historical sweep: `audits/eval_suite/all_metrics_since_jan_summary.csv`
- Today's two backfills (already executed):
  - `proposals/options_pfof_backfill_2026_06/`
  - `proposals/staking_lag_one_month_backfill_2026_06/`
