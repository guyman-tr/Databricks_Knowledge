-- Manual rewrite of DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour
-- Source: C:\Users\guyman\Desktop\lakebridge_transplier_v3\Stored Procedures\
--         DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour.sql
--
-- BladeBridge bug: inserted a stray `;` between the WITH-CTE definition
-- and the INSERT INTO that uses it, breaking the CTE binding.
-- Fix: bind the CTE to the INSERT in a single statement.

CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour(
    IN V_date TIMESTAMP
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
BEGIN
    INSERT INTO dwh_daily_process.migration_tables.Dim_GetSpreadedPriceUSDConversionRate
        (InstrumentID,
         DateFrom,
         BuyCurrencyID,
         SellCurrencyID,
         USD_ConversionRate,
         UpdateDate)
    WITH lp AS (
        SELECT  spc.InstrumentID,
                spc.DateFrom,
                spc.AskFirst  AS ASK,
                spc.BidFirst  AS Bid,
                spc.BuyCurrencyID,
                spc.SellCurrencyID
        FROM (
            SELECT DISTINCT A.*,
                   ROW_NUMBER() OVER (
                       PARTITION BY A.InstrumentID
                       ORDER BY DateFrom DESC
                   ) AS RN
            FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted A
            WHERE A.DateFrom = V_date
        ) spc
        WHERE spc.RN = 1
    )
    SELECT  a.InstrumentID,
            a.DateFrom,
            b.BuyCurrencyID,
            b.SellCurrencyID,
            CASE
                WHEN b.SellCurrencyID  =  1                                              THEN 1.00
                WHEN b.BuyCurrencyID   =  1                                              THEN 1.00 / b.Bid
                WHEN b.SellCurrencyID <> 1 AND b.BuyCurrencyID <> 1 AND c.BuyCurrencyID  = 1 THEN 1.00 / c.Bid
                WHEN b.SellCurrencyID <> 1 AND b.BuyCurrencyID <> 1 AND d.SellCurrencyID = 1 THEN d.Bid
            END AS USD_ConversionRate,
            current_timestamp() AS UpdateDate
    FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted a
    JOIN      lp b ON a.InstrumentID = b.InstrumentID
                   AND a.DateFrom    = b.DateFrom
    LEFT JOIN lp c ON b.SellCurrencyID = c.SellCurrencyID
                   AND c.BuyCurrencyID  = 1
    LEFT JOIN lp d ON b.SellCurrencyID = d.BuyCurrencyID
                   AND d.SellCurrencyID = 1
    WHERE a.DateFrom = V_date;
END;
