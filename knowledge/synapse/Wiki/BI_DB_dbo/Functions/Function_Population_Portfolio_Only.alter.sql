-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Portfolio_Only
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_population_portfolio_only
-- Col comments: 20 added, 0 preserved (existing), 1 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_portfolio_only (
  DateID,
  RealCID COMMENT 'COALESCE(position holder CID, options AUM RealCID). Source: Dim_Position.CID, Dim_Customer.RealCID. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only COMMENT 'Literal 1. Source:  - . (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END). Source: Dim_Position. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CFD_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CryptoCFD_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CryptoReal_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_StocksCFD_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_StocksReal_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_ETFCFD_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_ETFReal_Manual COMMENT 'MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END). Source: Dim_Position. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CFD_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CryptoCFD_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CryptoReal_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_StocksCFD_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_StocksReal_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_ETFCFD_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_ETFReal_Copy COMMENT 'MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Dim_Position, Dim_Instrument. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_CopyFund COMMENT 'MAX(CASE WHEN MirrorID > 0 AND IsCopyFund = 1 THEN 1 ELSE 0 END); IsCopyFund from Dim_Mirror.MirrorTypeID = 4. Source: Dim_Position, Dim_Mirror. (T2 - Function_Population_Portfolio_Only)',
  Portfolio_Only_Options COMMENT 'MAX(CASE WHEN PositionMarketValue > 0 THEN 1 ELSE 0 END). Source: External_Sodreconciliation_apex_EXT981_BuyPowerSummary. (T2 - Function_Population_Portfolio_Only)'
)
COMMENT 'BI_DB_dbo.Function_Population_Portfolio_Only > Identifies customers who qualify as portfolio-only under the DDR terminology framework: they hold open positions (or positive options buying power) in the date range but are not active traders in that same window. Flags break out manual vs copy, instrument families (CFD, crypto, stocks, ETF), copy-fund mirrors, and US options exposure from Apex buy-power data.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Population_Portfolio_Only > Identifies customers who qualify as portfolio-only under the DDR terminology framework: they hold open positions (or positive options buying power) in the date range but are not active traders in that same window. Flags break out manual vs copy, instrument families (CFD, crypto, stocks, ETF), copy-fund mirrors, and US options exposure from Apex buy-power data.')
WITH SCHEMA COMPENSATION
AS WITH snapshot_dates AS (
    SELECT DISTINCT DateID
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new
),
holders AS (
    SELECT
        bs.DateID,
        dp.CID AS RealCID,
        dp.MirrorID,
        dp.IsSettled,
        di.InstrumentTypeID,
        CASE WHEN dm.MirrorID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund
    FROM snapshot_dates bs
    INNER JOIN main.dwh.dim_position dp
        ON COALESCE(dp.IsAirDrop, 0) = 0
        AND dp.OpenDateID <= bs.DateID
        AND (dp.CloseDateID >= bs.DateID OR dp.CloseDateID = 0)
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN (
        SELECT MirrorID
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
        WHERE MirrorTypeID = 4
    ) dm ON dp.MirrorID = dm.MirrorID
),
options_aum AS (
    SELECT
        CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT) AS DateID,
        dc.RealCID,
        MAX(bps.PositionMarketValue) AS PositionMarketValue
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
    INNER JOIN main.general.bronze_usabroker_apex_options op
        ON bps.AccountNumber = op.OptionsApexID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON op.GCID = dc.GCID
    WHERE bps.OfficeCode IN ('4GS', '5GU')
        AND bps.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
    GROUP BY CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT), dc.RealCID
    HAVING MAX(bps.PositionMarketValue) > 0
),
merged AS (
    SELECT
        COALESCE(h.DateID, oa.DateID) AS DateID,
        COALESCE(h.RealCID, oa.RealCID) AS RealCID,
        h.MirrorID,
        h.IsSettled,
        h.InstrumentTypeID,
        h.IsCopyFund,
        oa.PositionMarketValue
    FROM holders h
    FULL OUTER JOIN options_aum oa
        ON h.DateID = oa.DateID
        AND h.RealCID = oa.RealCID
),
filtered2 AS (
    SELECT m.*
    FROM merged m
    WHERE m.RealCID IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM main.etoro_kpi_prep.v_population_active_traders pat
            WHERE pat.DateID = m.DateID
                AND pat.RealCID = m.RealCID
        )
)
SELECT
    f.DateID,
    f.RealCID,
    1 AS Portfolio_Only,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END) AS Portfolio_Only_CFD_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_CryptoCFD_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_CryptoReal_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_StocksCFD_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_StocksReal_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_ETFCFD_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_ETFReal_Manual,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END) AS Portfolio_Only_CFD_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_CryptoCFD_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_CryptoReal_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_StocksCFD_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_StocksReal_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_ETFCFD_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_ETFReal_Copy,
    MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.IsCopyFund, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_CopyFund,
    MAX(CASE WHEN COALESCE(f.PositionMarketValue, 0) > 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Options
FROM filtered2 f
GROUP BY f.DateID, f.RealCID

;
