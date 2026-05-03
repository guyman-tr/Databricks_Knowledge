-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_First_Trading_Action
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_population_first_trading_action
-- Col comments: 12 added, 8 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_first_trading_action (
  RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.',
  PositionID COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.',
  InstrumentID COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.',
  Instrument COMMENT 'Joined on first-action InstrumentID. Source: Dim_Instrument.Name. (T2 - Function_Population_First_Trading_Action)',
  InstrumentTypeID COMMENT 'Same join as row 4. Source: Dim_Instrument.InstrumentTypeID. (T2 - Function_Population_First_Trading_Action)',
  InstrumentType COMMENT 'Same join as row 4. Source: Dim_Instrument.InstrumentType. (T2 - Function_Population_First_Trading_Action)',
  IsSettled COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.',
  MirrorID COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.',
  Exchange COMMENT 'Same join as row 4. Source: Dim_Instrument.Exchange. (T2 - Function_Population_First_Trading_Action)',
  ISINCode COMMENT 'Same join as row 4. Source: Dim_Instrument.ISINCode. (T2 - Function_Population_First_Trading_Action)',
  IsAirDrop COMMENT 'ISNULL(IsAirDrop, 0) on first-action row (expected 0 given WHERE). Source: Fact_CustomerAction.IsAirDrop. (T2 - Function_Population_First_Trading_Action)',
  RN COMMENT 'ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID, Occurred); output keeps RN = 1. Source: Fact_CustomerAction. (T2 - Function_Population_First_Trading_Action)',
  IsCopyFund COMMENT 'CASE WHEN ISNULL(MirrorTypeID, 0) = 4 THEN 1 ELSE 0 END on first-action row. Source: Dim_Mirror.MirrorTypeID. (T2 - Function_Population_First_Trading_Action)',
  FirstTradeDateID COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes - key filter column.',
  Occurred COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  IsDepositor COMMENT 'Direct from Dim_Customer. Source: Dim_Customer.IsDepositor. (T1 - Function_Population_First_Trading_Action)',
  FirstDepositDate COMMENT 'Direct from Dim_Customer. Source: Dim_Customer.FirstDepositDate. (T1 - Function_Population_First_Trading_Action)',
  FirstTradeDate COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.',
  FirstDepositDateID COMMENT 'CAST(FORMAT(CAST(FirstDepositDate AS DATE), ''yyyyMMdd'') AS INT). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Trading_Action)',
  FirstActionType COMMENT 'CASE on InstrumentTypeID, MirrorID, IsCopyFund -> Forex / Crypto / Copy / Copy Fund / Stocks / NA. Source: Dim_Instrument, Fact_CustomerAction. (T2 - Function_Population_First_Trading_Action)'
)
COMMENT 'BI_DB_dbo.Function_Population_First_Trading_Action > Returns each customer’s first eligible trading-platform action row: Fact_CustomerAction with ActionTypeID IN (1, 17, 39) (open / mirror-style opens), (IsAirDrop = 0 OR IsAirDrop IS NULL), ordered by DateID, Occurred, ROW_NUMBER = 1 per RealCID. Optional @IsDepositor filters to Dim_Customer.IsDepositor = 1. FirstActionType rolls up instrument type and copy-fund mirror type.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Population_First_Trading_Action > Returns each customer’s first eligible trading-platform action row: Fact_CustomerAction with ActionTypeID IN (1, 17, 39) (open / mirror-style opens), (IsAirDrop = 0 OR IsAirDrop IS NULL), ordered by DateID, Occurred, ROW_NUMBER = 1 per RealCID. Optional @IsDepositor filters to Dim_Customer.IsDepositor = 1. FirstActionType rolls up instrument type and copy-fund mirror type.')
WITH SCHEMA COMPENSATION
AS SELECT 
    a.*,
    dc.IsDepositor,
    dc.FirstDepositDate,
    a.Occurred AS FirstTradeDate,
    CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS FirstDepositDateID,
    CASE 
        WHEN a.InstrumentTypeID IN (1,2,4) THEN 'Forex' 
        WHEN a.InstrumentTypeID = 10 THEN 'Crypto'
        WHEN a.MirrorID > 0 AND a.IsCopyFund = 0 THEN 'Copy'
        WHEN a.MirrorID > 0 AND a.IsCopyFund = 1 THEN 'Copy Fund'
        WHEN a.InstrumentTypeID IN (5,6) THEN 'Stocks'
        ELSE 'NA'
    END AS FirstActionType
FROM 
(
    SELECT
        dp.RealCID,
        dp.PositionID,
        dp.InstrumentID,
        di.Name AS Instrument,
        di.InstrumentTypeID,
        di.InstrumentType,
        dp.IsSettled,
        dp.MirrorID,
        di.Exchange,
        di.ISINCode,
        IFNULL(dp.IsAirDrop, 0) AS IsAirDrop,
        ROW_NUMBER() OVER (PARTITION BY dp.RealCID ORDER BY dp.DateID, dp.Occurred) AS RN,
        CASE WHEN IFNULL(dm.MirrorTypeID, 0) = 4 THEN 1 ELSE 0 END AS IsCopyFund,
        dp.DateID AS FirstTradeDateID,
        dp.Occurred
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction dp
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
        ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm
        ON dp.MirrorID = dm.MirrorID AND dm.MirrorTypeID = 4
    WHERE dp.ActionTypeID IN (1,17,39)
      AND (dp.IsAirDrop = 0 OR dp.IsAirDrop IS NULL)
) a
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON a.RealCID = dc.RealCID
WHERE a.RN = 1

;
