/*
================================================================================
  PATCH 1: main.etoro_kpi_prep.v_mimo_allplatforms
  Author:   Guy M
  Date:     2026-05-31

  Change:
    In moneyfarm_ftds CTE, AmountOrigCurrency was being set to FirstDepositAmount
    (which is USD-equivalent from Dim_Customer). The true GBP amount is not
    available from the MoneyFarm source - so the correct value is NULL.
    The previous behavior produced a +$4.66M phantom in the original-currency
    leg vs. Synapse (which uses the sentinel -1, also wrong but in a different
    direction).

    Per NULLs-over-sentinels rule: NULL is the correct semantic for
    "original-currency amount not available."

  Also bumping the AmountOrigCurrency column comment to reflect new behavior.
================================================================================
*/

CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_mimo_allplatforms (
  DateID            COMMENT 'Date key in YYYYMMDD integer format. Partition/filter key for daily DELETE/INSERT (TP+eMoney). Direct passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  Date              COMMENT 'Calendar date corresponding to DateID. `@date` SP input parameter. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  RealCID           COMMENT 'Customer identifier. Distribution key. Passthrough from sub-platform tables. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  MIMOAction        COMMENT 'Payment type code (check, wire, ACH, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT869_CashActivity)',
  OrigIdentifier    COMMENT 'Source-side identifier (depends on platform). NULL/blank for MoneyFarm (string DepositID literal). (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  TransactionID     COMMENT 'Source transaction identifier. `CAST(f.TransactionID AS VARCHAR(50))` for TP/eMoney; hardcoded `0` for Options and MoneyFarm (varchar incompatibility with lake schemas). (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  AmountUSD         COMMENT 'Transaction amount in USD equivalent. Passthrough from sub-platform tables. Negative values may appear for withdrawals depending on platform source. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  AmountOrigCurrency COMMENT 'Transaction amount in original currency. Passthrough from sub-platform tables. NULL for MoneyFarm (original GBP amount not available from source - Dim_Customer stores only USD-equivalent). Negative for withdrawals on TP. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  FundingTypeID     COMMENT 'Payment method identifier. Passthrough from sub-platform tables. `-1` sentinel for MoneyFarm. JOIN to `DWH_dbo.Dim_FundingType` for name. `FundingTypeID = 27` triggers C2USD UPDATE for TP. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  CurrencyID        COMMENT 'Currency identifier. Passthrough from sub-platform tables. `3` (GBP) hardcoded for MoneyFarm. JOIN to `DWH_dbo.Dim_Currency`. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  Currency          COMMENT 'Currency ISO code. Passthrough from sub-platform tables. `''GBP''` hardcoded for MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  IsPlatformFTD     COMMENT 'Platform-level first-time deposit flag. 1 = first deposit on this specific platform (TP, eMoney, Options, or MoneyFarm independently). Renamed from IsFTD. Updated by FTD recovery logic for DateID >= 20250901. Note: 13K bad-FTD cohort (Aug 18-20 2025 $1 FTDs) excluded via REMOVE_BAD_FTDS in Function_MIMO_First_Deposit_All_Platforms. (Tier 1 - Function_MIMO_First_Deposit_All_Platforms)',
  IsInternalTransfer COMMENT 'Internal fund transfer flag. `ISNULL(f.IsInternalTransfer, 0)`. 1 = transfer between platforms (TP <-> eMoney), not an external deposit/withdrawal. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  IsRedeem          COMMENT 'eMoney redemption flag. `ISNULL(f.IsRedeem, 0)`. 1 = eMoney balance redeemed to bank account. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  IsTradeFromIBAN   COMMENT 'eMoney-initiated trade flag. `ISNULL(f.IsIBANTrade, 0)`. Renamed from `IsIBANTrade` in sub-platform tables. 1 = deposit originated from eMoney IBAN. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  MIMOPlatform      COMMENT 'Platform discriminator. Values: TradingPlatform (CFD/Stocks TP), eMoney (IBAN/wallet), Options (Apex/US Options via Gatsby), MoneyFarm (UK managed investment - FTD only, no withdrawals). Options is full delete/re-insert every run due to unreliable data arrival. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  IsGlobalFTD       COMMENT 'Cross-platform first-time deposit flag. 1 = this deposit is the customer very first across ALL platforms. A deposit can be IsPlatformFTD=1 but IsGlobalFTD=0 (if customer already deposited on another platform). Old logic (IBAN+TP union) for FTDs before 2025-09-01; new logic (Dim_Customer-driven) for on/after. Excludes bad-FTD cohort. (Tier 1 - Function_MIMO_First_Deposit_All_Platforms)',
  IsCryptoToFiat    COMMENT 'Explicit literal `0` - reserved column (C2F captured on other DDR MIMO siblings). `INSERT SELECT ... , 0 AS IsCryptoToFiat`. PLUS `UPDATE` sets `1` for `FundingTypeID=27` TP deposits `DateID>=20250701`. eMoney uses `TxTypeID=14` per sibling. Options/MoneyFarm forced `0` on insert. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)',
  IsRecurring       COMMENT 'Recurring deposit flag. `ISNULL(f.IsRecurring, 0)`. 1 = deposit made via recurring/auto-deposit feature. Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  IsIBANQuickTransfer COMMENT 'eMoney Internal Transfer (quick transfer) flag. MoveMoneyReasonID=6. 1 = customer used the eMoney Internal Transfer feature to move funds. Distinct from TP internal transfers (IsInternalTransfer). Always 0 for Options/MoneyFarm. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)',
  UpdateDate        COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_Fact_MIMO_AllPlatforms)'
)
AS
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
    FirstDepositAmount AS AmountUSD,
    -- FIX 2026-05-31: NULL instead of FirstDepositAmount. MoneyFarm source does
    -- not expose the native GBP amount; Dim_Customer.FirstDepositAmount is the
    -- USD-equivalent. Setting orig=USD here was a phantom passthrough that
    -- inflated AmountOrigCurrency rollups by ~$4.66M/day.
    CAST(NULL AS DECIMAL(38,4)) AS AmountOrigCurrency,
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
  AND m.FTDPlatformID = gf.FTDPlatformID;
