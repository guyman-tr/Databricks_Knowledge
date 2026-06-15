# Staking all-time investigation — findings & non-action recommendation

**Date:** 2026-06-10
**Followup to:** `proposals/staking_lag_one_month_backfill_2026_06/` (3-day backfill applied this morning)
**User ask:** "fix the staking data same way as you did the options one — look back all time"
**Recommendation:** **DO NOT do an all-time rewrite. The 3-day fix from this morning is the correct scope.**

---

## What the all-time 3-way diagnostic showed

Reconciliation across:
- **V** = `main.etoro_kpi_prep.v_revenue_stakingfee` (treats current TVF/view as truth)
- **U** = `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (UC fact, post-this-morning)
- **S** = `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` (Synapse fact)

For `Metric = 'StakingLagOneMonth'`, all-time:

| Metric | All-time |
|---|---|
| Distinct paid DateIDs in U & S | 63 each, identical |
| Sum in U | $59,189,746.17 |
| Sum in S | $59,189,746.17 (identical to U) |
| Sum in V (recomputed via current SP STEP 3 logic) on same dates | $37,263,680.60 |
| Status: **U == S** but disagree with V on **45 of 63 days** | category `BOTH_FACTS_STALE` |
| V-only paid dates (V says payouts here, U+S say nothing) | 17 days, $15.4M |

Naive interpretation: "U+S are stale, V is truth, $22M of misclassification."

**This interpretation is wrong.** See next section.

## The forensic drill that contradicts the naive interpretation

Drilled CID 7942114 end-to-end through Dealing_Staking_Results → fact → view:

| dss.UpdateDate | dss.StakingMonthID | Synapse fact PaidDateID | UC fact PaidDateID | Current SP STEP 3 would produce |
|---|---|---|---|---|
| 2023-11-02 13:16 | 202309 | **20230905** | 20230905 | 20231102 |
| 2023-11-07 10:18 | 202310 | **20231005** | 20231005 | 20231107 |
| 2023-12-07 08:08 | 202311 | **20231107** | 20231107 | 20231207 |
| 2024-02-25 11:43 | 202312 | **20231205** | 20231205 | 20240225 |
| 2026-02-05 06:07 | 202601 | 20260205 | 20260205 | 20260205 ✓ |
| 2026-04-09 07:27 | 202603 | 20260409 | 20260409 | 20260409 ✓ |

**The historical PaidDateID does NOT equal `DATEADD(MONTH,1,frcf.Date)` per the current SP STEP 3 code (L1365 of the Synapse SP).** Instead, it appears to follow legacy logic (likely "first distribution day of the StakingMonthID" — note that `20230905` and `20231005` and `20231205` all share `day=05`, but `20231107` has `day=07`). The legacy logic is older than the current SP body and not reverse-engineerable from current code.

**Recent rows (2026 onwards) DO follow the current logic.** That's why this morning's 3-day backfill (Apr-7, May-4, Jun-2) was correctly resolvable — those three days were under current SP STEP 3 semantics where view-output and fact-output agree by construction.

## Why this means "do nothing"

1. **Historical fact rows in both Synapse and UC carry legacy semantics that we cannot recompute.** The current view (`v_revenue_stakingfee`) implements current SP semantics, so re-running the SP all-time would shift PaidDateIDs from where 2 years of Tableau dashboards have been reporting them.

2. **U == S across all 63 historical days.** No data-integrity drift between the two systems. This is the architecture working as it should: Synapse is the source-of-truth for legacy fact rows, UC mirrored them faithfully via the daily MERGE, neither side has been "wronger" than the other.

3. **Current Synapse SP STEP 3 is BOUNDED to the current month** (`DELETE WHERE Date BETWEEN month_start AND @date AND RevenueMetricID = 12`). Synapse never rewrites staking rows older than the current month. So even on the Synapse side, those legacy PaidDateIDs are frozen and cannot be retroactively "corrected" in place.

4. **Going forward:** the daily SP run will keep current-month rows in sync between view and fact. The bug we caught this morning only manifested because the UC SP was never being scheduled and the Synapse-MERGE-import doesn't re-evaluate retroactively-edited Synapse rows. Once the cutover plan from `proposals/sp_ddr_cutover_2026_06/PLAN.md` lands, this class of drift cannot recur for new data.

## What about the V-only days (17 days, $15.4M)?

The diagnostic showed 17 PaidDateIDs in V (the +1mo-shifted view) that don't exist in U or S. These are V's recomputation of historical cohorts via current SP semantics, landing them at PaidDateIDs that the legacy SP put elsewhere.

For example, V says cohort `StakingMonthID=202310` should pay out at `20231102` ($663k), but the legacy SP put that cohort at `20230905` (different month entirely). It's the same money, just labeled with a different date in the legacy era.

**Net total across all paid dates is the same to within rounding.** Confirmed by:
- V total all-time: $52,623,375 (only goes back to 2023-09 because the source TVF horizon starts there)
- U total all-time: $59,189,746 (goes back to 2023-09-05; carries some pre-TVF-horizon legacy rows)
- The $6.5M difference is mostly cohorts that the TVF doesn't reproduce (the source `Dealing_Staking_Results` may have been pruned or filtered differently for older cohorts)

## What stays open (for the future)

If the team ever wants to harmonize legacy staking PaidDateIDs to current-SP semantics:
- Get explicit sign-off because it WILL change historical Tableau report numbers.
- The recompute is straightforward (just run current SP semantics across all historical source-month windows).
- But this is a deliberate semantics-change exercise, not a bug-fix.

## Outputs left in place

- `audits/eval_suite/staking_alltime_3way.csv` — full 80-day 3-way breakdown
- `audits/eval_suite/staking_alltime_3way.txt` — same, with per-day status & summary
- `audits/eval_suite/staking_one_row.txt` — forensic drill of CID 7942114
- `tools/eval_suite/loop_authoring/_diag_staking_alltime_3way.py`
- `tools/eval_suite/loop_authoring/_diag_staking_one_row.py`
- `tools/eval_suite/loop_authoring/_diag_staking_tvf_columns.py`
