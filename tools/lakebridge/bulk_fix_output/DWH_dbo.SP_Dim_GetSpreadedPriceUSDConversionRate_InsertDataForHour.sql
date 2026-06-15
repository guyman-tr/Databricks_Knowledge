USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

/*
This procedure together with [DWH_dbo].SP_Dim_GetSpreadedPriceUSDConversionRate_DeleteByDateRange 
replaces [DWH_dbo].SP_Dim_GetSpreadedPriceUSDConversionRate.
The responsibility of this procedure is to insert data for a single hour
into [DWH_dbo].Dim_GetSpreadedPriceUSDConversionRate.

Usage:
EXEC [DWH_dbo].[SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour] '2022-01-13 05:00:00'
*/

WITH lp AS (
    SELECT spc.InstrumentID
        ,spc.DateFrom
        ,spc.AskFirst AS ASK
        ,spc.BidFirst AS Bid
        ,spc.BuyCurrencyID
        ,spc.SellCurrencyID
    FROM (
        SELECT DISTINCT A.*
            ,ROW_NUMBER() OVER (PARTITION BY A.InstrumentID ORDER BY DateFrom DESC) RN
        FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted A
        WHERE A.DateFrom =V_date
    ) spc
    WHERE spc.RN = 1 
);
INSERT INTO dwh_daily_process.migration_tables.Dim_GetSpreadedPriceUSDConversionRate
    (`InstrumentID`
    ,`DateFrom`
    ,`BuyCurrencyID`
    ,`SellCurrencyID`
    ,`USD_ConversionRate`
    ,UpdateDate)
SELECT a.InstrumentID
        ,a.DateFrom
        ,b.BuyCurrencyID
        ,b.SellCurrencyID
        ,CASE WHEN b.SellCurrencyID = 1 THEN 1.00
            WHEN b.BuyCurrencyID = 1 THEN 1.00 /  b.Bid
            WHEN b.SellCurrencyID <> 1 AND b.BuyCurrencyID <> 1 AND c.BuyCurrencyID = 1 THEN 1.00 / c.Bid
            WHEN b.SellCurrencyID <> 1 AND b.BuyCurrencyID <> 1 AND d.SellCurrencyID = 1 THEN   d.Bid
        END as USD_ConversionRate
        , current_timestamp() as UpdateDate
FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted a   	    		                
--LEFT 
JOIN lp b 
        ON a.InstrumentID = b.InstrumentID and a.DateFrom = b.DateFrom 
        LEFT JOIN lp c 
        ON b.SellCurrencyID = c.SellCurrencyID AND c.BuyCurrencyID = 1 --AND b.BuyCurrencyID <> 1 and c.DateFrom = b.DateFrom 
        LEFT JOIN lp d
        ON b.SellCurrencyID = d.BuyCurrencyID AND d.SellCurrencyID = 1 ---AND b.SellCurrencyID <> 1 and d.DateFrom = b.DateFrom 
WHERE a.DateFrom  = V_date
;
END;
