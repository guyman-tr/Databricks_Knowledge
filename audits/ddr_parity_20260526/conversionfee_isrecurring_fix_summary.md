# ConversionFee IsRecurring fix — DateID = 20260526

## What was wrong

`main.etoro_kpi_prep.v_fact_customeraction_w_metrics` was sourcing the
deposit-level `IsRecurring` flag from
`main.general.bronze_recurringinvestment_recurringinvestment_planinstances.DepositID`
(plan-instance recurring), while Synapse's `Function_Revenue_ConversionFee`
uses `Fact_BillingDeposit.IsRecurring` (billing-level recurring). The DBX
source covered only a subset, so ~55 deposit rows were silently classified
as `IsRecurring = 0` instead of `IsRecurring = 1` on 2026-05-26.

## Two-part fix

### Part 1: refactor `v_fact_customeraction_w_metrics`
Deployed in this session (replaces the view in-place).

| Change | Before | After |
|---|---|---|
| Deposit IsRecurring source | CTE on `bronze_recurringinvestment_recurringinvestment_planinstances` (plan instances) | `LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd` → `fbd.IsRecurring` |
| Position IsRecurring source | CTE on `bronze_recurringinvestment_recurringinvestment_planinstances` joined to `Dim_Position.OrderID` | `LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet rip` (direct mirror of Synapse) |
| `recurring_positions` CTE | present | removed |
| Dependency on `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | yes | **eliminated** |

The deposit branch now returns NULL when the deposit isn't in
`Fact_BillingDeposit` instead of coercing to 0, preserving NULL business
semantics (per the architecture decision logged in
`C:\Users\guyman\.cursor\memory\decisions.md`).

### Part 2: one-time partition reload
Script: [`one_time_fix_conversionfee_isrecurring_20260526.sql`](one_time_fix_conversionfee_isrecurring_20260526.sql)

`DELETE` + `INSERT` of `RevenueMetricID = 10 AND DateID = 20260526` from
the refactored `v_ddr_revenues`. 34,740 rows replaced in place.

Pre-fix Delta version: **471** (rollback target if needed; 7-day retention).

## Verification

| Bucket | DBX pre-fix | DBX post-fix | SYN |
|---|---|---|---|
| `IsRec = NULL` (Withdraws) | 16,001 / $166,407.59 | 16,001 / $166,407.59 | — (SYN coerces NULL→0) |
| `IsRec = 0` | 18,739 / $209,429.90 | 18,684 / $209,283.42 | 40,767 / $375,691.01 |
| `IsRec = 1` | 0 / $0.00 | **55 / $146.48** ✓ | 85 / $146.48 |
| **Total $** | $375,837.49 | $375,837.49 | $375,837.49 (NULL+0+1) |

- **Dollar parity** with Synapse achieved exactly:
  - DBX (NULL + 0) = $375,691.01 = SYN (IsRec=0)
  - DBX (IsRec=1) = $146.48 = SYN (IsRec=1)
- **Row-count gap** (55 vs 85 in IsRec=1, 34,685 vs 40,767 total) is
  Synapse SCD inflation in `Function_Revenue_ConversionFee`
  (`Fact_SnapshotCustomer + Dim_Range` joins emit duplicates) and is **not**
  a semantic difference. DBX correctly deduplicates.

## Scope rationale (why no historical backfill)

Older `DateID`s in this fact table are **imported from Synapse**, not produced
by the DBX SP. Those days already carry the Synapse-correct `IsRecurring`
flag (Synapse's `Function_Revenue_ConversionFee` always read
`Fact_BillingDeposit.IsRecurring`). The DBX SP only owns the days it computes
natively — 2026-05-26 onward — so the one-time fix only needs to touch this
single partition. Going forward, the refactored view ensures parity from
2026-05-27 onward without intervention.

## What is NOT included

- **`ELSE 0` → `ELSE NULL`**: the broader change to return NULL for all
  non-applicable action types (instead of 0) is out of scope here; the
  deposit branch is the only place where NULL semantics changed in this PR.
