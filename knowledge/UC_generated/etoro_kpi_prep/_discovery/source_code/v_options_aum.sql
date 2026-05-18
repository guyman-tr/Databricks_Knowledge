-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_options_aum
-- Captured: 2026-05-18T08:08:06Z
-- ==========================================================================

WITH buypower_ranked AS (
  SELECT 
    AccountNumber,
    ProcessDate,
    TotalEquity,
    CashEquity,
    PositionMarketValue,
    OfficeCode,
    ROW_NUMBER() OVER (PARTITION BY AccountNumber ORDER BY ProcessDate) AS RN,
    ROW_NUMBER() OVER (PARTITION BY CAST(ProcessDate AS DATE), AccountNumber ORDER BY ProcessDate DESC) AS daily_rn
  FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  WHERE OfficeCode IN ('4GS', '5GU')
    AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
),

first_funding AS (
  SELECT 
    AccountNumber,
    ProcessDate AS FirstFundingDate
  FROM buypower_ranked 
  WHERE RN = 1
),

latest_daily_buypower AS (
  SELECT
    AccountNumber,
    CAST(ProcessDate AS DATE) AS Date,
    TotalEquity,
    CashEquity,
    PositionMarketValue
  FROM buypower_ranked
  WHERE daily_rn = 1
)

SELECT DISTINCT
  op.GCID,
  CAST(DATE_FORMAT(bp.Date, 'yyyyMMdd') AS INT) AS DateID,
  bp.Date,
  CAST(bp.TotalEquity AS DECIMAL(18,2)) AS OptionsTotalEquity,
  CAST(bp.CashEquity AS DECIMAL(18,2)) AS OptionsCashEquity,
  CAST(bp.PositionMarketValue AS DECIMAL(18,2)) AS OptionsPositionMarketValue,
  CAST(DATE_FORMAT(CAST(ff.FirstFundingDate AS DATE), 'yyyyMMdd') AS INT) AS FirstOptionsAUMDateID,
  CAST(ff.FirstFundingDate AS DATE) AS FirstOptionsAUMDate
FROM latest_daily_buypower bp
INNER JOIN main.general.bronze_usabroker_apex_options op
  ON bp.AccountNumber = op.OptionsApexID
LEFT JOIN first_funding ff
  ON bp.AccountNumber = ff.AccountNumber
