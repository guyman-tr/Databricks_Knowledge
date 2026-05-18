-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_mimo_allplatforms
-- Captured: 2026-05-18T08:06:04Z
-- ==========================================================================

WITH global_ftds AS (
  SELECT RealCID, FTDPlatformID, FTDPlatform, FirstDepositDate, FirstDepositAmount, DepositID
  FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
),
tp_mimo AS (
  SELECT
    DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    IsFTD AS IsPlatformFTD, IsInternalTransfer, IsRedeem, IsIBANTrade,
    'TradingPlatform' AS MIMOPlatform,
    IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer,
    1 AS FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_tradingplatform
),
emoney_mimo AS (
  SELECT
    DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    IsFTD AS IsPlatformFTD, IsInternalTransfer, IsRedeem,
    IsTradeFromIBAN AS IsIBANTrade,
    'eMoney' AS MIMOPlatform,
    IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer,
    3 AS FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_emoneyplatform
),
options_mimo AS (
  SELECT
    DateID, Date, RealCID, MIMOAction,
    OfficeCode AS OrigIdentifier, TransactionID,
    AmountUSD, AmountUSD AS AmountOrigCurrency,
    FundingTypeID,
    1 AS CurrencyID, 'USD' AS Currency,
    IsFTD AS IsPlatformFTD, IsInternalTransfer,
    0 AS IsRedeem, 0 AS IsIBANTrade,
    'Options' AS MIMOPlatform,
    0 AS IsCryptoToFiat, 0 AS IsRecurring, 0 AS IsIBANQuickTransfer,
    2 AS FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_optionsplatform
),
moneyfarm_ftds AS (
  SELECT
    CAST(DATE_FORMAT(FirstDepositDate, 'yyyyMMdd') AS INT) AS DateID,
    CAST(FirstDepositDate AS DATE) AS Date,
    RealCID,
    'Deposit' AS MIMOAction, 'DepositID' AS OrigIdentifier,
    CAST(NULL AS BIGINT) AS TransactionID,
    FirstDepositAmount AS AmountUSD, FirstDepositAmount AS AmountOrigCurrency,
    -1 AS FundingTypeID, 3 AS CurrencyID, 'GBP' AS Currency,
    1 AS IsPlatformFTD, 0 AS IsInternalTransfer, 0 AS IsRedeem, 0 AS IsIBANTrade,
    'MoneyFarm' AS MIMOPlatform,
    0 AS IsCryptoToFiat, 0 AS IsRecurring, 0 AS IsIBANQuickTransfer,
    4 AS FTDPlatformID
  FROM global_ftds
  WHERE FTDPlatform = 'MoneyFarm'
),
unified_mimo AS (
  SELECT * FROM tp_mimo
  UNION ALL SELECT * FROM emoney_mimo
  UNION ALL SELECT * FROM options_mimo
  UNION ALL SELECT * FROM moneyfarm_ftds
)
SELECT
  m.DateID, m.Date, m.RealCID, m.MIMOAction, m.OrigIdentifier,
  CAST(m.TransactionID AS STRING) AS TransactionID,
  m.AmountUSD, m.AmountOrigCurrency, m.FundingTypeID, m.CurrencyID, m.Currency,
  COALESCE(m.IsPlatformFTD, 0) AS IsPlatformFTD,
  COALESCE(m.IsInternalTransfer, 0) AS IsInternalTransfer,
  COALESCE(m.IsRedeem, 0) AS IsRedeem,
  COALESCE(m.IsIBANTrade, 0) AS IsTradeFromIBAN,
  m.MIMOPlatform,
  CASE WHEN gf.RealCID IS NOT NULL THEN 1 ELSE 0 END AS IsGlobalFTD,
  -- FundingTypeID=27 override: crypto-to-fiat for TradingPlatform deposits (matches Synapse post-INSERT update)
  CASE
    WHEN m.FundingTypeID = 27 AND m.MIMOAction = 'Deposit' AND m.DateID >= 20250701 THEN 1
    ELSE COALESCE(m.IsCryptoToFiat, 0)
  END AS IsCryptoToFiat,
  COALESCE(m.IsRecurring, 0) AS IsRecurring,
  COALESCE(m.IsIBANQuickTransfer, 0) AS IsIBANQuickTransfer,
  CURRENT_TIMESTAMP() AS UpdateDate
FROM unified_mimo m
LEFT JOIN global_ftds gf
  ON m.MIMOAction = 'Deposit'
  AND m.RealCID = gf.RealCID
  AND m.IsPlatformFTD = 1
  AND m.FTDPlatformID = gf.FTDPlatformID
