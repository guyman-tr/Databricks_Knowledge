-- ============================================================================
-- One-time fix: ConversionFee IsRecurring backfill for DateID = 20260526
-- ============================================================================
--
-- CONTEXT
--   `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` was deriving the
--   deposit-level IsRecurring flag from
--   `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.DepositID`
--   (plan-instance recurring) instead of the canonical Synapse source
--   `Fact_BillingDeposit.IsRecurring` (billing-level recurring).
--   The view has been refactored to use Fact_BillingDeposit; this script
--   re-populates the day partition that was already written under the old logic.
--
-- WHAT THIS DOES
--   1. DELETE every ConversionFee (RevenueMetricID = 10) row for DateID = 20260526
--      from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions.
--   2. INSERT a fresh set of ConversionFee rows for DateID = 20260526 from
--      `main.etoro_kpi_prep.v_ddr_revenues` using the refactored view.
--
-- EXPECTED IMPACT (verified against Synapse for the same day)
--   Before:  NULL=16,001 ($166,407.59) + IsRec=0=18,739 ($209,429.90)              total $375,837.49
--   After :  NULL=16,001 ($166,407.59) + IsRec=0=18,684 ($209,283.42) + IsRec=1=55 ($146.48)  total $375,837.49
--   55 deposit rows shift from IsRec=0 to IsRec=1; aggregate dollar total preserved.
--   Synapse comparator (also for 20260526):  IsRec=1 = 85 rows / $146.48
--   Row-count gap (55 vs 85) is Synapse SCD inflation in the TVF
--   (Fact_SnapshotCustomer + Dim_Range duplication), NOT a semantic diff.
--   Dollar total ($146.48) matches Synapse exactly.
--
-- PRE-FLIGHT VERIFICATION (read-only — run first if reviewing)
--   SELECT IsRecurring, COUNT(*) rows, SUM(Amount) amt
--   FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
--   WHERE DateID = 20260526 AND RevenueMetricID = 10
--   GROUP BY IsRecurring ORDER BY IsRecurring;
--
-- NOTE
--   Databricks SQL does not support multi-statement transactions on Delta
--   tables. The two statements below are executed sequentially; each is
--   individually atomic via Delta. Run them in order. If the INSERT fails,
--   restore from Delta time-travel:
--     INSERT INTO <fact> SELECT * FROM <fact> VERSION AS OF <prev>
--     WHERE DateID = 20260526 AND RevenueMetricID = 10;
-- ============================================================================

-- Step 1: wipe the day's ConversionFee partition
DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE DateID = 20260526
  AND RevenueMetricID = 10;

-- Step 2: re-insert from the refactored view
INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions (
  DateID,
  Date,
  RealCID,
  ActionTypeID,
  ActionType,
  InstrumentTypeID,
  IsSettled,
  IsCopy,
  Metric,
  Amount,
  CountTransactions,
  IncludedInTotalRevenue,
  CountAsActiveTrade,
  UpdateDate,
  IsBuy,
  IsLeveraged,
  IsFuture,
  IsCopyFund,
  IsOpenedFromIBAN,
  IsClosedToIBAN,
  IsRecurring,
  IsAirDrop,
  IsSQF,
  RevenueMetricID,
  RevenueMetricCategoryID,
  IsMarginTrade,
  IsC2P
)
SELECT
  v.DateID,
  CAST(v.Date AS TIMESTAMP)              AS Date,
  v.RealCID,
  v.ActionTypeID,
  v.ActionType,
  v.InstrumentTypeID,
  v.IsSettled,
  v.IsCopy,
  v.Metric,
  CAST(v.Amount AS DECIMAL(16,6))        AS Amount,
  CAST(v.CountTransactions AS INT)       AS CountTransactions,
  v.IncludedInTotalRevenue,
  CAST(v.CountAsActiveTrade AS INT)      AS CountAsActiveTrade,
  current_timestamp()                    AS UpdateDate,
  v.IsBuy,
  v.IsLeveraged,
  v.IsFuture,
  v.IsCopyFund,
  v.IsOpenedFromIBAN,
  v.IsClosedToIBAN,
  v.IsRecurring,
  v.IsAirDrop,
  v.IsSQF,
  drm.RevenueMetricID,
  drm.RevenueMetricCategoryID,
  v.IsMarginTrade,
  v.IsC2P
FROM main.etoro_kpi_prep.v_ddr_revenues v
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics drm
  ON v.Metric = drm.Metric
WHERE v.Metric = 'ConversionFee'
  AND v.DateID = 20260526;

-- ============================================================================
-- POST-FLIGHT VERIFICATION
--   SELECT IsRecurring, COUNT(*) rows, SUM(Amount) amt
--   FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
--   WHERE DateID = 20260526 AND RevenueMetricID = 10
--   GROUP BY IsRecurring ORDER BY IsRecurring;
--   -- Expected: NULL/0/1 buckets with $146.48 in the IsRec=1 bucket
-- ============================================================================
