-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_ConversionFee_WithPositionData
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
-- Col comments: 17 added, 10 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata (
  CID COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.',
  ConversionFee COMMENT 'PIPsCalculation AS ConversionFee WHERE DateID BETWEEN @sdateInt AND @edateInt (and snapshot DateRange join). Source: BI_DB_DepositWithdrawFee.PIPsCalculation. (T2 — Function_Revenue_ConversionFee_WithPositionData)',
  TransactionType COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.TransactionType. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  IsIBANTrade COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.IsIBANTrade. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  TransactionID COMMENT 'CAST(LEFT(TransactionID, LEN(TransactionID) - 1) AS INT). Source: BI_DB_DepositWithdrawFee.TransactionID. (T2 — Function_Revenue_ConversionFee_WithPositionData)',
  PaymentMethod COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.PaymentMethod. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  Amount COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).',
  Currency COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.Currency. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  AmountUSD COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)',
  ExchangeRate COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)',
  BaseExchangeRate COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)',
  Depot COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.Depot. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  MIDValue COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.MIDValue. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  IsRecurring COMMENT 'Direct (LEFT JOIN on DepositID when TransactionType = ''Deposit''). Source: Fact_BillingDeposit.IsRecurring. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  PositionID COMMENT 'COALESCE(bdpcti.PositionID, bdpofi.PositionID). Source: BI_DB_Positions_Closed_To_IBAN.PositionID, BI_DB_Positions_Opened_From_IBAN.PositionID. (T2 — Function_Revenue_ConversionFee_WithPositionData)',
  IsSettled COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).',
  IsBuy COMMENT 'Trade direction: 1=Buy/Long (profits if price rises), 0=Sell/Short (profits if price falls).',
  Leverage COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.',
  IsAirDrop COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.',
  ExecutionIBANTradeSuccess COMMENT 'CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND IsIBANTrade = 1 THEN 0 ELSE 1 END. Source: BI_DB_DepositWithdrawFee.IsIBANTrade, BI_DB_Positions_Closed_To_IBAN, BI_DB_Positions_Opened_From_IBAN. (T2 — Function_Revenue_ConversionFee_WithPositionData)',
  InstrumentID COMMENT 'Direct pass-through from Dim_Instrument.InstrumentID. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  InstrumentTypeID COMMENT 'Direct pass-through from Dim_Instrument.InstrumentTypeID. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  InstrumentType COMMENT 'Direct pass-through from Dim_Instrument.InstrumentType. (T1 — Function_Revenue_ConversionFee_WithPositionData)',
  IsCopy COMMENT 'CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END. Source: Dim_Position.MirrorID. (T2 — Function_Revenue_ConversionFee_WithPositionData)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_ConversionFee_WithPositionData)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_ConversionFee_WithPositionData > Same grain as Function_Revenue_ConversionFee: ConversionFee = PIPsCalculation with DateID BETWEEN @sdateInt AND @edateInt (plus snapshot Dim_Range join). Adds position-level attributes for IBAN-linked flows via BI_DB_Positions_Opened_From_IBAN / BI_DB_Positions_Closed_To_IBAN, then Dim_Position / Dim_Instrument, and ExecutionIBANTradeSuccess when IBAN trade rows lack a resolved position.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_ConversionFee_WithPositionData > Same grain as Function_Revenue_ConversionFee: ConversionFee = PIPsCalculation with DateID BETWEEN @sdateInt AND @edateInt (plus snapshot Dim_Range join). Adds position-level attributes for IBAN-linked flows via BI_DB_Positions_Opened_From_IBAN / BI_DB_Positions_Closed_To_IBAN, then Dim_Position / Dim_Instrument, and ExecutionIBANTradeSuccess when IBAN trade rows lack a resolved position.')
WITH SCHEMA COMPENSATION
AS SELECT
    fca.CID,
    fsc.GCID,
    fca.DateID,
    fca.PIPsCalculation AS ConversionFee,
    fca.TransactionType,
    fca.IsIBANTrade,
    CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) AS TransactionID,
    fca.PaymentMethod,
    fca.Amount,
    fca.Currency,
    fca.AmountUSD,
    fca.ExchangeRate,
    fca.BaseExchangeRate,
    fca.Depot,
    fca.MIDValue,
    fbd.IsRecurring,
    COALESCE(bdpcti.PositionID, bdpofi.PositionID) AS PositionID,
    dp.IsSettled,
    dp.IsBuy,
    dp.Leverage,
    dp.IsAirDrop,
    CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND fca.IsIBANTrade = 1 THEN 0 ELSE 1 END AS ExecutionIBANTradeSuccess,
    di.InstrumentID,
    di.InstrumentTypeID,
    di.InstrumentType,
    CASE WHEN dp.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy,
    fsc.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd
    ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbd.DepositID
    AND fca.TransactionType = 'Deposit'
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw fbw
    ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbw.WithdrawPaymentID
    AND fca.TransactionType = 'Withdraw'
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban bdpofi
    ON fca.DepositID = bdpofi.DepositID
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban bdpcti
    ON fca.WithdrawPaymentID = bdpcti.WithdrawPaymentID
LEFT JOIN main.dwh.dim_position dp
    ON COALESCE(bdpcti.PositionID, bdpofi.PositionID) = dp.PositionID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON dp.InstrumentID = di.InstrumentID

;
