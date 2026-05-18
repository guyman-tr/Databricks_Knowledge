-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_mimo_tradingplatform
-- Captured: 2026-05-18T08:06:43Z
-- ==========================================================================

WITH deposits_tp AS (
  SELECT
    fca.DateID,
    to_date(CAST(fca.DateID AS STRING), 'yyyyMMdd') AS Date,
    fca.RealCID,
    fca.DepositID,
    fca.Amount AS AmountUSD,
    fbd.Amount AS AmountOrigCurrency,
    fbd.FundingTypeID,
    fbd.CurrencyID,
    dc.Abbreviation AS Currency,
    CASE WHEN dc1.FTDTransactionID = fca.DepositID THEN 1 ELSE 0 END AS IsFTD,
    CASE WHEN fbd.FundingTypeID = 33 THEN 1 ELSE 0 END AS IsInternalTransfer,
    NULL AS IsRedeem,
    fbd.IsRecurring,
    CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END AS IsIBANTrade,
    CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd
    ON fca.DepositID = fbd.DepositID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc
    ON fbd.CurrencyID = dc.CurrencyID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
    ON fca.RealCID = dc1.RealCID
    AND dc1.FTDPlatformID = 1
  WHERE fca.ActionTypeID IN (7, 44)
),
cashout_tp AS (
  SELECT
    fca.DateID,
    to_date(CAST(fca.DateID AS STRING), 'yyyyMMdd') AS Date,
    fca.RealCID,
    fca.WithdrawPaymentID,
    fca.Amount AS AmountUSD,
    COALESCE(
      bddwf.Amount,
      ROUND(ROUND(fbw.Amount_WithdrawToFunding, 6) / ROUND(fbw.ExchangeRate, 6), 6)
    ) AS AmountOrigCurrency,
    fbw.FundingTypeID_Funding AS FundingTypeID,
    fbw.ProcessCurrencyID AS CurrencyID,
    dc.Abbreviation AS Currency,
    fca.IsFTD,
    CASE WHEN fbw.FundingTypeID_Funding = 33 THEN 1 ELSE 0 END AS IsInternalTransfer,
    fca.IsRedeem,
    NULL AS IsRecurring,
    CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0 END AS IsIBANTrade,
    CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw fbw
    ON fca.WithdrawPaymentID = fbw.WithdrawPaymentID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc
    ON fbw.ProcessCurrencyID = dc.CurrencyID
  LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee bddwf
    ON fca.DateID = bddwf.DateID
    AND bddwf.TransactionType = 'Withdraw'
    AND TRY_CAST(REPLACE(bddwf.TransactionID, 'W', '') AS INT) = fca.WithdrawPaymentID
  WHERE fca.ActionTypeID IN (8, 45)
),
mimo_combined AS (
  SELECT
    DateID, Date, RealCID,
    'Deposit' AS MIMOAction, 'DepositID' AS OrigIdentifier, DepositID AS TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    IsFTD, IsInternalTransfer, 0 AS IsRedeem, COALESCE(IsRecurring, 0) AS IsRecurring,
    IsIBANTrade, IsIBANQuickTransfer
  FROM deposits_tp
  UNION ALL
  SELECT
    DateID, Date, RealCID,
    'Withdraw' AS MIMOAction, 'WithdrawPaymentID' AS OrigIdentifier, WithdrawPaymentID AS TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    0 AS IsFTD, IsInternalTransfer, IsRedeem, 0 AS IsRecurring,
    IsIBANTrade, IsIBANQuickTransfer
  FROM cashout_tp
),
mimo_deduped AS (
  SELECT *
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY MIMOAction, TransactionID ORDER BY TransactionID) AS rn
    FROM mimo_combined
  )
  WHERE rn = 1
)
SELECT
  DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
  AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
  COALESCE(IsFTD, 0) AS IsFTD,
  COALESCE(IsInternalTransfer, 0) AS IsInternalTransfer,
  COALESCE(IsRedeem, 0) AS IsRedeem,
  COALESCE(IsRecurring, 0) AS IsRecurring,
  COALESCE(IsIBANTrade, 0) AS IsIBANTrade,
  0 AS IsCryptoToFiat,
  COALESCE(IsIBANQuickTransfer, 0) AS IsIBANQuickTransfer,
  CURRENT_TIMESTAMP() AS UpdateDate
FROM mimo_deduped
