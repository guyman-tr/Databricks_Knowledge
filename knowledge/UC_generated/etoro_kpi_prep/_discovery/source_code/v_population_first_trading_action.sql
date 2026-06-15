-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_first_trading_action
-- Captured: 2026-05-19T12:19:34Z
-- ==========================================================================

SELECT 
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
