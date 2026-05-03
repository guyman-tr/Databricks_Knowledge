-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Active_Traders
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_population_active_traders
-- Col comments: 12 added, 3 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_active_traders (
  GCID COMMENT 'Global Customer ID - platform-wide unique customer identifier. References Dim_Customer.GCID.',
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  DateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes - key filter column.',
  ActiveTraded COMMENT '1. Source: (literal). (T2 - Function_Population_Active_Traders)',
  ActiveTradedManual COMMENT 'MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END) over rows matching TP filters (ActionTypeID IN (1,39,15,17), IsAirDrop=0, valid customer, date range) union options branch (ActionTypeID = 1). Source: Fact_CustomerAction, Function_Revenue_OptionsPlatform. (T2 - Function_Population_Active_Traders)',
  ActiveTradedCFD COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedCryptoCFD COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedCryptoReal COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedStocksCFD COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedStocksReal COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedETFCFD COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedETFReal COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Dim_Instrument, options branch. (T2 - Function_Population_Active_Traders)',
  ActiveTradedCopy COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15,17) THEN 1 ELSE 0 END) - open/close copy actions only on TP leg (options use MirrorID = 0). Source: Fact_CustomerAction, Function_Revenue_OptionsPlatform. (T2 - Function_Population_Active_Traders)',
  ActiveTradedCopyFund COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15,17) AND IsCopyFund = 1 THEN 1 ELSE 0 END) with IsCopyFund from Dim_Mirror.MirrorTypeID = 4. Source: Fact_CustomerAction, Dim_Mirror. (T2 - Function_Population_Active_Traders)',
  ActiveTradedOptions COMMENT 'Same eligible rowset as row 5; MAX(CASE WHEN InstrumentTypeID = 9 THEN 1 ELSE 0 END). Source: Fact_CustomerAction, Function_Revenue_OptionsPlatform. (T2 - Function_Population_Active_Traders)'
)
COMMENT 'BI_DB_dbo.Function_Population_Active_Traders > Flags DDR-style “active traders” per customer per DateID inside [@sdateInt, @edateInt]. TP leg: Fact_CustomerAction with ActionTypeID IN (1, 39, 15, 17), ISNULL(IsAirDrop,0) = 0, customer in Fact_SnapshotCustomer with IsValidCustomer = 1, DateID in range and inside snapshot Dim_Range. Options leg: Function_Revenue_OptionsPlatform(@sdateInt, @edateInt, 1) rows with ActionTypeID = 1, joined to Dim_Customer for GCID. Unioned rows drive MAX(CASE …) asset-class and copy flags.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Population_Active_Traders > Flags DDR-style “active traders” per customer per DateID inside [@sdateInt, @edateInt]. TP leg: Fact_CustomerAction with ActionTypeID IN (1, 39, 15, 17), ISNULL(IsAirDrop,0) = 0, customer in Fact_SnapshotCustomer with IsValidCustomer = 1, DateID in range and inside snapshot Dim_Range. Options leg: Function_Revenue_OptionsPlatform(@sdateInt, @edateInt, 1) rows with ActionTypeID = 1, joined to Dim_Customer for GCID. Unioned rows drive MAX(CASE …) asset-class and copy flags.')
WITH SCHEMA COMPENSATION
AS WITH actionsprep AS (
    SELECT
        fca.GCID,
        fca.RealCID,
        fca.Occurred,
        fca.ActionTypeID,
        fca.MirrorID,
        fca.DateID,
        fca.IsSettled,
        di.InstrumentTypeID,
        CASE WHEN dm.MirrorID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON fca.RealCID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON fsc.DateRangeID = dr.DateRangeID
        AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON fca.InstrumentID = di.InstrumentID
    LEFT JOIN (
        SELECT MirrorID
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
        WHERE MirrorTypeID = 4
    ) dm ON fca.MirrorID = dm.MirrorID
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
        frop.InstrumentTypeID,
        COALESCE(frop.IsCopyFund, 0) AS IsCopyFund
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
        MAX(CASE WHEN f.MirrorID > 0 AND f.ActionTypeID IN (15, 17) AND f.IsCopyFund = 1 THEN 1 ELSE 0 END) AS ActiveTradedCopyFund,
        MAX(CASE WHEN f.InstrumentTypeID = 9 THEN 1 ELSE 0 END) AS ActiveTradedOptions
    FROM activetypes_prep f
    GROUP BY f.GCID, f.RealCID, f.DateID
)
SELECT * FROM activetypes

;
