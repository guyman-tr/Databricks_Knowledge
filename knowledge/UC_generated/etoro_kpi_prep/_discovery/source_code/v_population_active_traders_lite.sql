-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_active_traders_lite
-- Captured: 2026-05-19T12:17:31Z
-- ==========================================================================

WITH actionsprep AS (
    SELECT
        fca.GCID,
        fca.RealCID,
        fca.Occurred,
        fca.ActionTypeID,
        fca.MirrorID,
        fca.DateID,
        fca.IsSettled,
        di.InstrumentTypeID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON fca.RealCID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON fsc.DateRangeID = dr.DateRangeID
        AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON fca.InstrumentID = di.InstrumentID
    WHERE fca.ActionTypeID IN (1, 39, 15, 17)
        AND COALESCE(fca.IsAirDrop, 0) = 0
        AND fsc.IsValidCustomer = 1
),
active_options AS (
    SELECT
        dc.GCID,
        frop.RealCID,
        CAST(frop.Date AS TIMESTAMP) AS Occurred,
        frop.ActionTypeID,
        CAST(0 AS INT) AS MirrorID,
        frop.DateID,
        frop.IsSettled,
        frop.InstrumentTypeID
    FROM main.etoro_kpi_prep.v_revenue_optionsplatform frop
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON frop.RealCID = dc.RealCID
    WHERE frop.ActionTypeID = 1
        AND COALESCE(frop.IsAirDrop, 0) = 0
        AND frop.IsValidCustomer = 1
),
activetypes_prep AS (
    SELECT * FROM actionsprep
    UNION ALL
    SELECT * FROM active_options
),
activetypes AS (
    SELECT
        f.GCID,
        f.RealCID,
        f.DateID,
        1 AS ActiveTraded,
        MAX(CASE WHEN f.MirrorID = 0 THEN 1 ELSE 0 END) AS ActiveTradedManual,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END) AS ActiveTradedCFD,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (10) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedCryptoCFD,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (10) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedCryptoReal,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (5) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedStocksCFD,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (5) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedStocksReal,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (6) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedETFCFD,
        MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (6) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedETFReal,
        MAX(CASE WHEN f.MirrorID > 0 AND f.ActionTypeID IN (15, 17) THEN 1 ELSE 0 END) AS ActiveTradedCopy,
        MAX(CASE WHEN f.InstrumentTypeID = 9 THEN 1 ELSE 0 END) AS ActiveTradedOptions
    FROM activetypes_prep f
    GROUP BY f.GCID, f.RealCID, f.DateID
)
SELECT * FROM activetypes
