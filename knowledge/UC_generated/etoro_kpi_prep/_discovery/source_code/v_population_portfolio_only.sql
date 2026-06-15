-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_portfolio_only
-- Captured: 2026-05-19T12:20:19Z
-- ==========================================================================

WITH snapshot_dates AS (
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
