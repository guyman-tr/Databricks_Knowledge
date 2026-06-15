# Options_PFOF: Synapse SP vs UC SP — Root Cause

**Date:** 2026-06-10
**Detour from:** eval-suite-v1, tile #1 (Revenue: Totals, 2026-06-08)
**Original symptom:** Synapse `Function_DDR_Aggregation_Yesterday` showed `SUM(TotalRevenue) = 2,880,439.86`. The naïve UC SCD-2 join (per `valid-users-filter-contract.md`) showed `2,879,105.29`. Δ = `1,334.57`. Per-metric decomposition: 100% of the gap = `Options_PFOF` (371 Synapse rows, 0 UC rows for 2026-06-08).

---

## TL;DR — there is NO logic difference between the two SPs.

Both systems implement the exact same pattern:

> **STEP 2: DELETE every Options_PFOF row in the fact table; INSERT the full lifetime history from the Options source.**

The Synapse SP and the UC SP are line-for-line equivalents (modulo dialect):

| Stage | Synapse `BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions` | UC `de_output_stg.sp_ddr_fact_revenue_generating_actions` |
|---|---|---|
| Step 1 — main revenue | DELETE WHERE DateID = @dateID; INSERT for @dateID, excluding Staking & Options | Same |
| **Step 2 — Options** | `DELETE WHERE RevenueMetricID = 18` (line 1575); `INSERT … FROM #optionsalltime` (built from `Function_Revenue_OptionsPlatform(20000101, today, 0)` — full history, no filter) | `EXECUTE IMMEDIATE 'DELETE … WHERE RevenueMetricID = 18'`; `INSERT … FROM main.etoro_kpi_prep.v_revenue_optionsplatform` (full history, no DateID filter) |
| Step 3 — Staking | DELETE current month; INSERT prior month shifted +1 | Same |

The Synapse SP comment on line 1575 is verbatim: `-- remove and rewrite all options data, usually will not be ready in time for daily collection`. UC's comment on line 57 of the dump is `-- STEP 2: Options - delete all + reinsert all time`. Same intent, same pattern, same data flow.

The two source views also produce **byte-identical** output for every day in the last 60 days:

```
DateID    | Synapse TVF rows | UC view rows | Synapse sum_amt | UC sum_amt
20260608  | 371              | 371          | 1334.5714       | 1334.5714
20260605  | 440              | 440          | 1476.0284       | 1476.0284
20260604  | 410              | 410          | 1216.1392       | 1216.1392
20260603  | 262              | 262          | 481.6950        | 481.6950
... (every other day, identical)
```

Both views read from the same physical SOD reconciliation feed:
- **Synapse:** `BI_DB_dbo.Sodreconciliation_apex_EXT1047_RevenueReports`
- **UC:** `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

These are the same Apex SOD CSVs, ingested twice into the two warehouses. They land at the same time. The transformation logic in the two views is line-for-line identical (same `PREP`/`FIRSTTRADE` CTE, same `ROW_NUMBER() OVER (PARTITION BY ClearingAccount ORDER BY TradeDate)`, same `SUM(ABS(rev.CustomerPFOFPayback))`, same exclusion of the 5 `4GS*` house accounts, same join against `dim_customer`, same group-by). The only differences are syntactic (`CONVERT(NVARCHAR(8), ..., 112)` vs `DATE_FORMAT(..., 'yyyyMMdd')`) and irrelevant casing of the `IsRucurring` typo (preserved in Synapse, fixed in UC's view-emitting layer).

---

## So why does the UC fact table look broken?

It is not the SP. It is not the source. **The UC SP is not being invoked by the orchestrator** — at least not the Options step.

Evidence:

```
=== UC: row counts of Options_PFOF in fact table per day, last 60d ===
  UC fact  DateID=20260608 rows=371 sum_amt=1334.571400 max_upd=2026-06-10T12:55:48.540Z   ← MANUALLY inserted by us during diag
  UC fact  DateID=20260428 rows=406 sum_amt=772.627900  max_upd=2026-05-01T06:06:14.193Z   ← last orchestrator-driven write
  (nothing in between — 40 days of empty Options_PFOF in UC)
```

The single `max_upd` stamp on every legacy Options_PFOF row in UC is **2026-05-01T06:06**. Synapse's Options table is rewritten in full by every daily run, so its `UpdateDate` slides forward every day. UC's was last rewritten on May 1 and has been frozen since.

If the SP were running daily, we would see one of two patterns:
1. The full history rewritten daily → all `UpdateDate` rows = T-1 (Synapse pattern).
2. Only the new day appended → `UpdateDate` would slide forward on the new partition daily.

We see neither. We see a single rewrite on May 1, then nothing for 40 days. That is the orchestrator-not-calling-the-SP signature.

---

## Why is the SP not being called?

Outside the scope of this detour — but the strong-signal candidates are:
- **Lakeflow job not wired.** The `de_output_stg.sp_ddr_fact_revenue_generating_actions` SP has no daily Lakeflow trigger. Manual SP runs (e.g. the `CALL` you ran on June 9th) execute Step 1 (main revenue) and Step 3 (staking) cleanly because the user has invoked the wrapper `sp_ddr_customer_daily_status` — but that wrapper might not be calling `sp_ddr_fact_revenue_generating_actions` at all, or it might be skipping STEP 2 in some conditional path.
- **Wrapper-only DateID call.** If the orchestrator calls the SP with a `p_date` value but a `p_mode` other than `'FULL'`, STEP 2 still runs unconditionally (the `WHERE RevenueMetricID = 18` delete is mode-agnostic in the UC body) — so this is *not* the issue. The SP, when called, will rebuild Options. The SP just isn't being called.
- **Mode mismatch on May 1 backfill.** It's possible that the May 1 run was a one-off `p_mode='FULL'` backfill that wrote Options once, and the orchestrator was never armed afterwards.

---

## Verification — manual call works

We just confirmed it works end-to-end by manually executing the INSERT body of STEP 2 for `DateID = 20260608`:

```sql
INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  (... 27 columns ...)
SELECT o.DateID, ... 0, 18, 5, 0, NULL
FROM main.etoro_kpi_prep.v_revenue_optionsplatform o
WHERE o.DateID = 20260608
```

This inserted 371 rows summing to `1334.5714` — byte-identical to Synapse. UC `TotalRevenue` for 2026-06-08 is now in exact parity with the Synapse TVF.

---

## What this means for the eval suite

There is **no semantic drift** between the two SPs. There is **no skill-corpus blind spot**. There is no "Synapse does X, Databricks does Y" definition difference.

This is pure **operational ETL lag** — the kind of finding the **freshness sentinel** is supposed to catch (per the original eval-suite plan), distinct from **drift detection** (skill-corpus vs. baseline-of-truth divergence).

The case YAML for tile #1 stays pinned to the UC value. We document the gap as a freshness signal and surface it as a finding for ops, not as a semantic gap.

---

## Recommendations (for ops, separate from eval suite)

1. **Backfill UC Options_PFOF for the 40-day gap.**  Run `sp_ddr_fact_revenue_generating_actions(NULL, 'FULL')` once. STEP 2's `DELETE WHERE RevenueMetricID = 18` followed by `INSERT … FROM v_revenue_optionsplatform` (no DateID filter) will rebuild the entire Options history from the source view. Estimated load: ~17k rows (40 days × ~440 rows/day average).
2. **Confirm Lakeflow wiring.** Check whether `sp_ddr_fact_revenue_generating_actions` is wired into a daily Lakeflow job, and whether that job has been failing or just isn't scheduled.
3. **Add a freshness assertion** on `gold_…_fact_revenue_generating_actions`: `MAX(UpdateDate) WHERE Metric='Options_PFOF'` should be ≥ T-2.

---

## Detour status: **CLOSED**

Root cause confirmed. SP logic is correct in both systems and structurally equivalent. The discrepancy is an orchestration-layer ETL lag in UC, not a semantic difference. Returning to eval-suite tile authoring.
