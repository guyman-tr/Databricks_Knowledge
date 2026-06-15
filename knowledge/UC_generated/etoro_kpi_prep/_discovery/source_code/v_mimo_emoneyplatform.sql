-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_mimo_emoneyplatform
-- Captured: 2026-05-19T12:13:45Z
-- ==========================================================================

WITH ftd_iban AS (
  SELECT
    mfts.CID,
    COALESCE(dc1.FirstDepositDate, mfts.TxStatusModificationTime) AS TxStatusModificationTime,
    COALESCE(dc1.FirstDepositAmount, mfts.USDAmountApprox) AS USDAmountApprox,
    mfts.TransactionID,
    ROW_NUMBER() OVER (PARTITION BY CID ORDER BY mfts.TxStatusModificationTime) AS RN,
    mfts.SourceCugTransactionID
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
    ON dc1.FTDTransactionID = mfts.SourceCugTransactionID
    AND dc1.FTDPlatformID = 3
  WHERE mfts.TxStatusID = 2
    AND mfts.TxTypeID IN (7, 14)
),
deposits_iban AS (
  SELECT
    mfts.TxStatusModificationDateID AS DateID,
    CAST(mfts.TxStatusModificationDate AS DATE) AS Date,
    mfts.CID AS RealCID,
    'Deposit' AS MIMOAction,
    'TransactionID' AS OrigIdentifier,
    mfts.TransactionID,
    mfts.ReferenceNumber,
    COALESCE(f.USDAmountApprox, mfts.USDAmountApprox) AS AmountUSD,
    mfts.LocalAmount AS AmountOrigCurrency,
    CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END AS FundingTypeID,
    dc.CurrencyID,
    mfts.HolderCurrencyDesc AS Currency,
    CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END AS IsFTD,
    CASE WHEN mfts.TxTypeID IN (5) THEN 1 ELSE 0 END AS IsInternalTransfer,
    NULL AS IsRedeem,
    mfts.TxTypeID,
    CASE
       WHEN LEFT(ReferenceNumber, 1) != 'P'
         AND TxStatusModificationDateID >= 20240403
         AND TxTypeID = 5
       THEN 1
       ELSE 0
     END AS IsTradeFromIBAN,
    CASE WHEN mfts.TxTypeID IN (14) THEN 1 ELSE 0 END AS IsCryptoToFiat
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc
    ON mfts.HolderCurrencyISO = dc.Abbreviation
  LEFT JOIN ftd_iban f
    ON mfts.TransactionID = f.TransactionID
  WHERE mfts.TxStatusID = 2
    AND mfts.TxTypeID IN (7, 5, 14)
),
cashout_iban AS (
  SELECT
    mfts.TxStatusModificationDateID AS DateID,
    CAST(mfts.TxStatusModificationDate AS DATE) AS Date,
    mfts.CID AS RealCID,
    'Withdraw' AS MIMOAction,
    'TransactionID' AS OrigIdentifier,
    mfts.TransactionID,
    mfts.ReferenceNumber,
    -1 * mfts.USDAmountApprox AS AmountUSD,
    -1 * mfts.LocalAmount AS AmountOrigCurrency,
    CASE WHEN mfts.TxTypeID IN (6) THEN 33 ELSE 0 END AS FundingTypeID,
    dc.CurrencyID,
    mfts.HolderCurrencyDesc AS Currency,
    0 AS IsFTD,
    CASE WHEN mfts.TxTypeID IN (6) THEN 1 ELSE 0 END AS IsInternalTransfer,
    NULL AS IsRedeem,
    mfts.TxTypeID,
    CASE
       WHEN LEFT(ReferenceNumber, 1) != 'P'
         AND TxStatusModificationDateID >= 20240403
         AND TxTypeID = 6
       THEN 1
       ELSE 0
     END AS IsTradeFromIBAN,
    0 AS IsCryptoToFiat
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc
    ON mfts.HolderCurrencyDesc = dc.Abbreviation
  WHERE mfts.TxStatusID = 2
    AND mfts.TxTypeID IN (8, 6)
),
mimo_iban_prep AS (
  SELECT * FROM deposits_iban
  UNION ALL
  SELECT * FROM cashout_iban
),
mimo_iban_deduped AS (
  SELECT *
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY TransactionID) AS RN
    FROM mimo_iban_prep
  )
  WHERE RN = 1
)
SELECT
  DateID, Date, RealCID, MIMOAction, OrigIdentifier,
  COALESCE(TransactionID, -1) AS TransactionID,
  COALESCE(ReferenceNumber, '-1') AS ReferenceNumber,
  AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
  COALESCE(IsFTD, 0) AS IsFTD,
  COALESCE(IsInternalTransfer, 0) AS IsInternalTransfer,
  COALESCE(IsRedeem, 0) AS IsRedeem,
  TxTypeID,
  COALESCE(IsTradeFromIBAN, 0) AS IsTradeFromIBAN,
  COALESCE(IsCryptoToFiat, 0) AS IsCryptoToFiat,
  0 AS IsRecurring,
  0 AS IsIBANQuickTransfer,
  CURRENT_TIMESTAMP() AS UpdateDate
FROM mimo_iban_deduped
