-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_ConversionFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_conversionfee
-- Col comments: 11 added, 6 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_conversionfee (
  CID COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_ConversionFee)',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.',
  ConversionFee COMMENT 'PIPsCalculation AS ConversionFee WHERE DateID BETWEEN @sdateInt AND @edateInt (and snapshot DateRange join). Source: BI_DB_DepositWithdrawFee.PIPsCalculation. (T2 — Function_Revenue_ConversionFee)',
  TransactionType COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.TransactionType. (T1 — Function_Revenue_ConversionFee)',
  IsIBANTrade COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.IsIBANTrade. (T1 — Function_Revenue_ConversionFee)',
  TransactionID COMMENT 'CAST(LEFT(TransactionID, LEN(TransactionID) - 1) AS INT). Source: BI_DB_DepositWithdrawFee.TransactionID. (T2 — Function_Revenue_ConversionFee)',
  PaymentMethod COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.PaymentMethod. (T1 — Function_Revenue_ConversionFee)',
  Amount COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).',
  Currency COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.Currency. (T1 — Function_Revenue_ConversionFee)',
  AmountUSD COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)',
  ExchangeRate COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)',
  BaseExchangeRate COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)',
  Depot COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.Depot. (T1 — Function_Revenue_ConversionFee)',
  MIDValue COMMENT 'Direct pass-through from BI_DB_DepositWithdrawFee.MIDValue. (T1 — Function_Revenue_ConversionFee)',
  IsRecurring COMMENT 'Direct (LEFT JOIN on DepositID when TransactionType = ''Deposit''). Source: Fact_BillingDeposit.IsRecurring. (T1 — Function_Revenue_ConversionFee)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_ConversionFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_ConversionFee > Returns deposit/withdraw conversion-fee rows from BI_DB_DepositWithdrawFee: ConversionFee is PIPsCalculation for rows with DateID BETWEEN @sdateInt AND @edateInt, joined to customer snapshot as-of the fee date (Dim_Range) and optionally to Fact_BillingDeposit / Fact_BillingWithdraw to expose IsRecurring on matched deposits (LEFT JOIN on parsed TransactionID when TransactionType is Deposit or Withdraw).'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_ConversionFee > Returns deposit/withdraw conversion-fee rows from BI_DB_DepositWithdrawFee: ConversionFee is PIPsCalculation for rows with DateID BETWEEN @sdateInt AND @edateInt, joined to customer snapshot as-of the fee date (Dim_Range) and optionally to Fact_BillingDeposit / Fact_BillingWithdraw to expose IsRecurring on matched deposits (LEFT JOIN on parsed TransactionID when TransactionType is Deposit or Withdraw).')
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

;
