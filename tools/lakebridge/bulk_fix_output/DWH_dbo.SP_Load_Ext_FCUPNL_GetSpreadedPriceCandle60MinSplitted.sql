USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Load_Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted(
IN V_Yesterday TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

    

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted;
    INSERT INTO dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted 
    (
          `rn`
        , `InstrumentID`
        , `AskLast`
        , `BidLast`
        , `AskFirst`
        , `DateFrom`
    )
    SELECT 
          ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY DateFrom DESC) AS rn
        , InstrumentID
        , CAST(AskLast  AS DECIMAL(16,8)) AS AskLast
        , CAST(BidLast  AS DECIMAL(16,8)) AS BidLast
        , CAST(AskFirst AS DECIMAL(16,8)) AS AskFirst
        , DateFrom
    FROM dwh_daily_process.daily_snapshot.PriceLog_Candles_GetSpreadedPriceCandle60MinSplitted
    WHERE DateFrom < V_Yesterday;

END;
