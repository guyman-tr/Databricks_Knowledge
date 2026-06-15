-- =====================================================================
-- v_mimo_allplatforms (aligned)
-- ---------------------------------------------------------------------
-- Holds ALL the MIMO logic — IsPlatformFTD, IsGlobalFTD, IsCryptoToFiat,
-- cross-platform unification, bad-cohort filtering, late-arriving FTD
-- recovery. The SP (sp_ddr_fact_mimo_allplatforms) is a thin materializer
-- that just SELECTs from this view per date.
--
-- ALIGNMENT vs CURRENT PRODUCTION VIEW
--   The current production view UNIONs the 4 per-platform sources and
--   sets IsGlobalFTD via a LEFT JOIN to v_mimo_first_deposit_all_platforms.
--   Two semantic gaps vs Synapse:
--     (a) IsPlatformFTD passes through from the per-platform views,
--         which mark any DimCustomer match as IsFTD = 1 — INCLUDING
--         bad-cohort customers. Synapse intends both flags to co-move
--         with bad-cohort status. This view applies the bad-cohort
--         filter to IsPlatformFTD too.
--     (b) Late-arriving DimCustomer FTDs are handled implicitly: the
--         per-platform views compute IsFTD from CURRENT Dim_Customer
--         state, so a rerun of the SP for any historical date will
--         pick up DimCustomer updates that arrived after the original
--         daily load. (Synapse achieves the same via the recovery
--         UPDATE in the SP; DBX achieves it via the view recomputing
--         from current source on every materialization. Workflow: to
--         back-date a fix, rerun the SP for the affected DateIDs.)
--
-- INPUTS
--   - main.etoro_kpi_prep.v_mimo_tradingplatform   (TP raw, computes
--                                                   IsFTD via DimCustomer)
--   - main.etoro_kpi_prep.v_mimo_emoneyplatform    (eMoney raw, same)
--   - main.etoro_kpi_prep.v_mimo_optionsplatform   (Options raw)
--   - main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
--                                                   (filtered FTD set
--                                                    — the TVF)
--   - main.etoro_kpi_prep.v_bad_ftd_cohort         (predicate, single
--                                                    source of cohort)
--
-- OUTPUTS (one row per MIMO transaction)
--   DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
--   AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
--   IsPlatformFTD, IsInternalTransfer, IsRedeem, IsTradeFromIBAN,
--   MIMOPlatform, IsGlobalFTD, IsCryptoToFiat, IsRecurring,
--   IsIBANQuickTransfer, UpdateDate
-- =====================================================================
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_mimo_allplatforms AS
WITH
v_bad AS (
  SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort
),
global_ftds AS (
  -- Already filters bad cohort via v_mimo_first_deposit_all_platforms.
  SELECT
    RealCID, FTDPlatformID, FTDPlatform,
    FirstDepositDate, FirstDepositAmount, DepositID
  FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
),
tp_mimo AS (
  SELECT
    DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    IsFTD AS IsPlatformFTD_raw,
    IsInternalTransfer, IsRedeem, IsIBANTrade,
    'TradingPlatform' AS MIMOPlatform,
    IsCryptoToFiat, IsRecurring, IsIBANQuickTransfer,
    1 AS FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_tradingplatform
),
emoney_mimo AS (
  SELECT
    DateID, Date, RealCID, MIMOAction, OrigIdentifier, TransactionID,
    AmountUSD, AmountOrigCurrency, FundingTypeID, CurrencyID, Currency,
    IsFTD AS IsPlatformFTD_raw,
    IsInternalTransfer, IsRedeem,
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
    IsFTD AS IsPlatformFTD_raw,
    IsInternalTransfer,
    0 AS IsRedeem, 0 AS IsIBANTrade,
    'Options' AS MIMOPlatform,
    0 AS IsCryptoToFiat, 0 AS IsRecurring, 0 AS IsIBANQuickTransfer,
    2 AS FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_optionsplatform
),
moneyfarm_ftds AS (
  -- MoneyFarm has no native MIMO feed — synthesize FTD-only rows
  -- from the filtered TVF (global_ftds already excludes bad cohort).
  -- AmountOrigCurrency is NULL: native GBP not available from source
  -- (user preference: NULL over -1 sentinel).
  SELECT
    CAST(DATE_FORMAT(FirstDepositDate, 'yyyyMMdd') AS INT) AS DateID,
    CAST(FirstDepositDate AS DATE) AS Date,
    RealCID,
    'Deposit' AS MIMOAction,
    'DepositID' AS OrigIdentifier,
    CAST(NULL AS BIGINT) AS TransactionID,
    FirstDepositAmount AS AmountUSD,
    CAST(NULL AS DECIMAL(38,4)) AS AmountOrigCurrency,
    -1 AS FundingTypeID,
    3 AS CurrencyID,
    'GBP' AS Currency,
    1 AS IsPlatformFTD_raw,
    0 AS IsInternalTransfer,
    0 AS IsRedeem,
    0 AS IsIBANTrade,
    'MoneyFarm' AS MIMOPlatform,
    0 AS IsCryptoToFiat,
    0 AS IsRecurring,
    0 AS IsIBANQuickTransfer,
    4 AS FTDPlatformID
  FROM global_ftds
  WHERE FTDPlatform = 'MoneyFarm'
),
unified_raw AS (
  SELECT * FROM tp_mimo
  UNION ALL SELECT * FROM emoney_mimo
  UNION ALL SELECT * FROM options_mimo
  UNION ALL SELECT * FROM moneyfarm_ftds
),
unified_mimo AS (
  -- Apply bad-cohort filter to IsPlatformFTD.
  -- If RealCID is currently bad-cohort, IsPlatformFTD is forced to 0,
  -- regardless of what the raw feed says.
  SELECT
    u.DateID, u.Date, u.RealCID, u.MIMOAction, u.OrigIdentifier,
    u.TransactionID,
    u.AmountUSD, u.AmountOrigCurrency, u.FundingTypeID,
    u.CurrencyID, u.Currency,
    u.IsInternalTransfer, u.IsRedeem, u.IsIBANTrade,
    u.MIMOPlatform,
    u.IsCryptoToFiat, u.IsRecurring, u.IsIBANQuickTransfer,
    u.FTDPlatformID,
    CASE
      WHEN COALESCE(u.IsPlatformFTD_raw, 0) = 1 AND b.RealCID IS NULL THEN 1
      ELSE 0
    END AS IsPlatformFTD
  FROM unified_raw u
  LEFT JOIN v_bad b ON u.RealCID = b.RealCID
)
SELECT
  m.DateID,
  m.Date,
  m.RealCID,
  m.MIMOAction,
  m.OrigIdentifier,
  CAST(m.TransactionID AS STRING) AS TransactionID,
  m.AmountUSD,
  m.AmountOrigCurrency,
  m.FundingTypeID,
  m.CurrencyID,
  m.Currency,
  m.IsPlatformFTD,
  COALESCE(m.IsInternalTransfer, 0) AS IsInternalTransfer,
  COALESCE(m.IsRedeem, 0) AS IsRedeem,
  COALESCE(m.IsIBANTrade, 0) AS IsTradeFromIBAN,
  m.MIMOPlatform,
  -- IsGlobalFTD: the JOIN requires the (already filtered) IsPlatformFTD = 1.
  -- Bad-cohort customers have IsPlatformFTD = 0 → JOIN fails → IsGlobalFTD = 0.
  -- Un-blacklisted customers (count > 1) appear in global_ftds and have
  --   IsPlatformFTD = 1 → JOIN matches → IsGlobalFTD = 1.
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
  ON  m.MIMOAction      = 'Deposit'
  AND m.RealCID         = gf.RealCID
  AND m.IsPlatformFTD   = 1
  AND m.FTDPlatformID   = gf.FTDPlatformID;

COMMENT ON VIEW main.etoro_kpi_prep.v_mimo_allplatforms IS
'Unified MIMO view across TP / eMoney / Options / MoneyFarm. Encodes all FTD logic: bad-cohort filter (via v_bad_ftd_cohort applied to IsPlatformFTD), filtered global FTD JOIN (via v_mimo_first_deposit_all_platforms applied to IsGlobalFTD), IsCryptoToFiat synthesis. The SP sp_ddr_fact_mimo_allplatforms is a thin materializer over this view — all semantic logic lives here.';
