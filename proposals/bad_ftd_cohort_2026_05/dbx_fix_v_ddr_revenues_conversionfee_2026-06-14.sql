-- =================================================================================================
-- FIX: main.etoro_kpi_prep.v_ddr_revenues  (ConversionFee row-count parity with Synapse)
-- =================================================================================================
-- Root cause (verified 2026-06-14, see ROOT_CAUSE_DDR_DIVERGENCE_2026-06-14.md):
--
--   Synapse's SP for ConversionFee:
--     SELECT ..., sum(ConversionFee), count(CID), ISNULL(IsRecurring,0)
--     FROM Function_Revenue_ConversionFee(@dateID, @dateID, 0)
--     GROUP BY DateID, CID, TransactionType, ISNULL(IsRecurring,0);
--   → keeps zero-fee rows (sums them at $0 with CountTransactions > 0).
--
--   DBX v_ddr_revenues.unpivoted applies NULLIF(..., 0.0) to the three ConversionFee variants,
--   followed by WHERE m.MetricAmount IS NOT NULL.  This silently drops every transaction with
--   ConversionFee = 0 BEFORE the group-by, eliminating CIDs whose (TT, IsRecurring) bucket sums
--   to exactly $0.  Verified for DateID 20260613:
--
--     Synapse grouped rows = 12,065
--       └─ 10,453 with non-zero sum  ← matches DBX exactly
--       └─  1,612 with zero sum      ← dropped by NULLIF in DBX
--
-- Fix:
--   A. Remove the `NULLIF(..., 0.0)` wrapper on the three ConversionFee variants in the STACK call.
--      Zero-fee rows now flow through, get aggregated, and the (CID, ActionType, IsRecurring) tuple
--      survives even when the sum is $0.  Sum_amount unchanged (was already correct).
--   B. (Cosmetic, kept from prior revision) extend d_IsRecurring's IN-list to all three ConversionFee
--      variants so the dimension is uniformly applied — matches Synapse's `ISNULL(IsRecurring,0)`
--      applied per-row.  No row impact today (no Withdraw IsRecurring=1 in current data) but keeps
--      the dimension semantically aligned.
-- =================================================================================================

CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_ddr_revenues (
  DateID COMMENT 'Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 - ETL-computed)',
  Date,
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 - Customer.CustomerStatic)',
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
  IsBuy,
  IsLeveraged,
  IsFuture,
  IsCopyFund,
  IsOpenedFromIBAN,
  IsClosedToIBAN,
  IsRecurring,
  IsAirDrop,
  IsSQF,
  IsC2P,
  IsMarginTrade)
WITH SCHEMA COMPENSATION
AS SELECT
  DateID,
  to_date(CAST(DateID AS STRING), 'yyyyMMdd') AS Date,
  RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsSettled, IsCopy,
  Metric, Amount, CountTransactions, IncludedInTotalRevenue, CountAsActiveTrade,
  IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN,
  IsRecurring, IsAirDrop, IsSQF, IsC2P, IsMarginTrade
FROM (
  WITH base AS (
    SELECT
      v.DateID,
      v.RealCID,
      v.ActionTypeID,
      dat.Name AS ActionTypeName,
      di.InstrumentTypeID,
      CAST(v.IsSettled AS INT) AS IsSettled,
      CASE WHEN v.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy,
      CAST(v.IsBuy AS INT) AS IsBuy,
      CASE WHEN v.Leverage > 1 THEN 1 ELSE 0 END AS IsLeveraged,
      COALESCE(CAST(di.IsFuture AS INT), 0) AS IsFuture,
      CAST(v.IsAirDrop AS INT) AS IsAirDrop,
      v.IsCopyFund,
      v.IsOpenFromIBAN AS IsOpenedFromIBAN,
      v.IsClosedToIBAN,
      v.IsRecurring,
      v.IsSQF,
      v.IsC2P,
      v.IsActiveTrade,
      v.SettlementTypeID,
      v.IsFeeDividend,
      v.IsRedeem,
      v.CompensationReasonID,
      v.FullCommissionTotal,
      v.CommissionTotal,
      v.RollOverFee,
      v.Dividend,
      v.SDRT,
      v.TicketFeeOpen + v.TicketFeeClose AS TicketFee,
      v.AdminFee,
      v.SpotAdjustFee,
      v.CashoutFeeExludingRedeem,
      v.ConversionFeeDeposit,
      v.ConversionFeeWithdraw,
      v.ConversionFeeReversal,
      v.DormantFee,
      v.TransferCoinFee,
      v.ShareLendingGrossAmount
    FROM main.etoro_kpi_prep.v_fact_customeraction_w_metrics v
      LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON v.InstrumentID = di.InstrumentID
      LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype dat
        ON v.ActionTypeID = dat.ActionTypeID
  ),
  unpivoted AS (
    SELECT
      b.DateID, b.RealCID, b.ActionTypeID, b.ActionTypeName, b.InstrumentTypeID,
      b.IsSettled, b.IsCopy, b.IsBuy, b.IsLeveraged, b.IsFuture, b.IsAirDrop,
      b.IsCopyFund, b.IsOpenedFromIBAN, b.IsClosedToIBAN, b.IsRecurring,
      b.IsSQF, b.IsC2P, b.IsActiveTrade, b.SettlementTypeID,
      m.MetricName, m.MetricAmount
    FROM base b
    LATERAL VIEW STACK(15,
      'FullCommission', CASE WHEN b.ActionTypeID IN (1,2,3,39,4,5,6,28,40) THEN CAST(b.FullCommissionTotal AS DOUBLE) END,
      'Commission',     CASE WHEN b.ActionTypeID IN (1,2,3,39,4,5,6,28,40) THEN CAST(b.CommissionTotal AS DOUBLE) END,
      'RollOverFee',    CASE WHEN b.ActionTypeID = 35 AND b.IsFeeDividend = 1 THEN CAST(b.RollOverFee AS DOUBLE) END,
      'Dividends',      CASE WHEN b.ActionTypeID = 35 AND b.IsFeeDividend = 2 THEN CAST(b.Dividend AS DOUBLE) END,
      'SDRT',           CASE WHEN b.ActionTypeID = 35 AND b.IsFeeDividend = 3 THEN CAST(b.SDRT AS DOUBLE) END,
      'TicketFee',      CASE WHEN b.ActionTypeID = 35 AND b.IsFeeDividend = 4 THEN CAST(b.TicketFee AS DOUBLE) END,
      'AdminFee',       CASE WHEN b.ActionTypeID = 36 AND b.CompensationReasonID = 117 THEN CAST(b.AdminFee AS DOUBLE) END,
      'SpotPriceAdjustment', CASE WHEN b.ActionTypeID = 36 AND b.CompensationReasonID = 118 THEN CAST(b.SpotAdjustFee AS DOUBLE) END,
      'CashoutFeeExclRedeem', CASE WHEN b.ActionTypeID = 30 AND b.IsRedeem = 0 THEN CAST(b.CashoutFeeExludingRedeem AS DOUBLE) END,
      -- ░░░ FIX A: drop NULLIF only on Deposit/Withdraw (they have ActionTypeID gates that
      --             isolate the right rows; zero-fee rows should survive to match Synapse).
      --             Keep NULLIF on Reversal — it has NO ActionTypeID gate, so NULLIF is the
      --             only signal that the row is an actual reversal (column is 0.0 on most rows). ░░░
      'ConversionFeeDeposit',  CASE WHEN b.ActionTypeID IN (7, 44) THEN CAST(b.ConversionFeeDeposit AS DOUBLE) END,
      'ConversionFeeWithdraw', CASE WHEN b.ActionTypeID IN (8, 45) THEN CAST(b.ConversionFeeWithdraw AS DOUBLE) END,
      'ConversionFeeReversal', NULLIF(CAST(b.ConversionFeeReversal AS DOUBLE), 0.0),
      'DormantFee',     CASE WHEN b.ActionTypeID = 36 AND b.CompensationReasonID = 30 THEN CAST(b.DormantFee AS DOUBLE) END,
      'TransferCoinFee',CASE WHEN b.ActionTypeID = 30 AND b.IsRedeem = 1 THEN CAST(b.TransferCoinFee AS DOUBLE) END,
      'ShareLending',   CASE WHEN b.ActionTypeID = 36 AND b.CompensationReasonID = 119 THEN CAST(b.ShareLendingGrossAmount AS DOUBLE) END
    ) m AS MetricName, MetricAmount
    WHERE m.MetricAmount IS NOT NULL
  ),
  dimensioned AS (
    SELECT
      DateID, RealCID, MetricName, MetricAmount, IsActiveTrade,
      CASE WHEN MetricName IN ('FullCommission','Commission') THEN ActionTypeID END AS d_ActionTypeID,
      CASE
        WHEN MetricName IN ('FullCommission','Commission') THEN ActionTypeName
        WHEN MetricName = 'RollOverFee' THEN 'Rollover'
        WHEN MetricName = 'ConversionFeeDeposit' THEN 'Deposit'
        WHEN MetricName = 'ConversionFeeWithdraw' THEN 'Withdraw'
        WHEN MetricName = 'ConversionFeeReversal' THEN 'Reversal'
        WHEN MetricName = 'TransferCoinFee' THEN 'Redeem'
        ELSE MetricName
      END AS d_ActionType,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN InstrumentTypeID
        WHEN MetricName = 'TransferCoinFee' THEN 10
        WHEN MetricName = 'ShareLending' THEN 5
      END AS d_InstrumentTypeID,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsSettled
        WHEN MetricName IN ('TransferCoinFee','ShareLending') THEN 1
      END AS d_IsSettled,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsCopy
        WHEN MetricName = 'ShareLending' THEN 0
      END AS d_IsCopy,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsBuy
        WHEN MetricName = 'ShareLending' THEN 1
      END AS d_IsBuy,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsLeveraged
        WHEN MetricName = 'ShareLending' THEN 0
      END AS d_IsLeveraged,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsFuture
        WHEN MetricName = 'ShareLending' THEN 0
      END AS d_IsFuture,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsCopyFund
        WHEN MetricName = 'ShareLending' THEN 0
      END AS d_IsCopyFund,
      CASE WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsOpenedFromIBAN END AS d_IsOpenedFromIBAN,
      CASE WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsClosedToIBAN END AS d_IsClosedToIBAN,
      -- ░░░ FIX: include Withdraw + Reversal so they split on IsRecurring like Synapse does ░░░
      CASE WHEN MetricName IN (
        'FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment',
        'ConversionFeeDeposit','ConversionFeeWithdraw','ConversionFeeReversal'
      ) THEN IsRecurring END AS d_IsRecurring,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsAirDrop
        WHEN MetricName = 'DormantFee' THEN 0
      END AS d_IsAirDrop,
      CASE WHEN MetricName IN ('FullCommission','Commission','RollOverFee','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsSQF END AS d_IsSQF,
      CASE WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','SDRT','TicketFee','AdminFee','SpotPriceAdjustment') THEN IsC2P END AS d_IsC2P,
      CASE
        WHEN MetricName IN ('FullCommission','Commission','RollOverFee','Dividends','TicketFee','AdminFee','SpotPriceAdjustment') THEN CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END
        WHEN MetricName = 'SDRT' THEN 0
      END AS d_IsMarginTrade
    FROM unpivoted
  )
  SELECT
    DateID, RealCID,
    d_ActionTypeID AS ActionTypeID,
    d_ActionType AS ActionType,
    d_InstrumentTypeID AS InstrumentTypeID,
    d_IsSettled AS IsSettled,
    d_IsCopy AS IsCopy,
    CASE WHEN MetricName LIKE 'ConversionFee%' THEN 'ConversionFee' ELSE MetricName END AS Metric,
    SUM(MetricAmount) AS Amount,
    COUNT(*) AS CountTransactions,
    CASE WHEN MetricName IN ('Commission','Dividends','SDRT') THEN 0 ELSE 1 END AS IncludedInTotalRevenue,
    CASE WHEN MetricName IN ('FullCommission','Commission') THEN SUM(IsActiveTrade) ELSE 0 END AS CountAsActiveTrade,
    d_IsBuy AS IsBuy, d_IsLeveraged AS IsLeveraged, d_IsFuture AS IsFuture,
    d_IsCopyFund AS IsCopyFund, d_IsOpenedFromIBAN AS IsOpenedFromIBAN, d_IsClosedToIBAN AS IsClosedToIBAN,
    d_IsRecurring AS IsRecurring, d_IsAirDrop AS IsAirDrop, d_IsSQF AS IsSQF,
    d_IsC2P AS IsC2P, d_IsMarginTrade AS IsMarginTrade
  FROM dimensioned
  GROUP BY DateID, RealCID, MetricName,
    d_ActionTypeID, d_ActionType, d_InstrumentTypeID, d_IsSettled, d_IsCopy,
    d_IsBuy, d_IsLeveraged, d_IsFuture, d_IsCopyFund, d_IsOpenedFromIBAN,
    d_IsClosedToIBAN, d_IsRecurring, d_IsAirDrop, d_IsSQF, d_IsC2P, d_IsMarginTrade

  UNION ALL

  SELECT
    DateID, RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsSettled, IsCopy,
    Metric, CAST(Amount AS DOUBLE) AS Amount,
    CountTransactions, IncludedInTotalRevenue, CountAsActiveTrade,
    IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN,
    IsRecurring, IsAirDrop,
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT)
  FROM main.etoro_kpi_prep.v_revenue_optionsplatform

  UNION ALL

  SELECT
    LastModificationDateID, RealCID,
    CAST(NULL AS INT), 'C2F',
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    'CryptoToFiatFee',
    SUM(CAST(TotalFeeUSD AS DOUBLE)),
    COUNT(*), 1, 0,
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT)
  FROM main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
  GROUP BY LastModificationDateID, RealCID

  UNION ALL

  SELECT
    DateID, RealCID,
    CAST(NULL AS INT), 'InterestFee',
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    'InterestFee',
    SUM(CAST(InterestFee AS DOUBLE)),
    COUNT(*), 1, 0,
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT),
    CAST(NULL AS INT), CAST(NULL AS INT), CAST(NULL AS INT)
  FROM main.etoro_kpi_prep.v_revenue_interestfee
  WHERE InterestFee IS NOT NULL
  GROUP BY DateID, RealCID

  UNION ALL

  SELECT
    CAST(DATE_FORMAT(ADD_MONTHS(Date, 1), 'yyyyMMdd') AS INT) AS DateID,
    CAST(CID AS INT) AS RealCID,
    CAST(NULL AS INT) AS ActionTypeID, 'Staking' AS ActionType,
    10 AS InstrumentTypeID, 1 AS IsSettled, CAST(NULL AS INT) AS IsCopy,
    'StakingLagOneMonth' AS Metric,
    SUM(CAST(TotalUSDDistributed AS DOUBLE)) AS Amount,
    CAST(NULL AS INT) AS CountTransactions, 1 AS IncludedInTotalRevenue, 0 AS CountAsActiveTrade,
    1 AS IsBuy, 0 AS IsLeveraged, 0 AS IsFuture,
    0 AS IsCopyFund, CAST(NULL AS INT) AS IsOpenedFromIBAN, CAST(NULL AS INT) AS IsClosedToIBAN,
    CAST(NULL AS INT) AS IsRecurring, CAST(NULL AS INT) AS IsAirDrop,
    CAST(NULL AS INT) AS IsSQF, CAST(NULL AS INT) AS IsC2P, CAST(NULL AS INT) AS IsMarginTrade
  FROM main.etoro_kpi_prep.v_revenue_stakingfee
  GROUP BY CAST(DATE_FORMAT(ADD_MONTHS(Date, 1), 'yyyyMMdd') AS INT), CID
) t;
