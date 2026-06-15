USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_GetSpreadedPriceUSDConversionRate(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_date TIMESTAMP ;

DECLARE V_nextdate  TIMESTAMP
;
DECLARE V_prevweekdate  TIMESTAMP
;
/*
2022-07-05  Boris   Add code to delete duplicate rows

*/

SET V_date = cast(cast(current_timestamp() - INTERVAL 1 DAY AS date) as TIMESTAMP)
;
SET V_nextdate = DATEADD(day, 1, V_date)
;
SET V_prevweekdate = DATEADD(week, -1, V_date);
--select @date, @nextdate,@prevweekdate
DELETE FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceUSDConversionRate
where `DateFrom` between V_prevweekdate and V_nextdate


    ;
WHILE V_prevweekdate < V_nextdate
    DO
--   drop table if EXISTS #price

DROP VIEW IF EXISTS TEMP_TABLE_price;

        CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_price AS
SELECT DISTINCT A.*
			           ,ROW_NUMBER() OVER (PARTITION BY A.InstrumentID ORDER BY DateFrom DESC) RN
         
        FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted A
        WHERE A.DateFrom =V_prevweekdate;

       -- drop table if EXISTS #LastPrice
DROP VIEW IF EXISTS TEMP_TABLE_LastPrice;

        CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_LastPrice AS
SELECT InstrumentID
              ,DateFrom
	          ,AskFirst AS ASK
	          ,BidFirst AS Bid
	          ,BuyCurrencyID
	          ,SellCurrencyID
        
        FROM TEMP_TABLE_price 
        WHERE RN = 1;

        --WHILE @prevweekdate < @nextdate
        --BEGIN
        --print @prevweekdate
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
        JOIN TEMP_TABLE_LastPrice b 
	           ON a.InstrumentID = b.InstrumentID and a.DateFrom = b.DateFrom 
              LEFT JOIN TEMP_TABLE_LastPrice c 
	           ON b.SellCurrencyID = c.SellCurrencyID AND c.BuyCurrencyID = 1 --AND b.BuyCurrencyID <> 1 and c.DateFrom = b.DateFrom 
              LEFT JOIN TEMP_TABLE_LastPrice d
	           ON b.SellCurrencyID = d.BuyCurrencyID AND d.SellCurrencyID = 1 ---AND b.SellCurrencyID <> 1 and d.DateFrom = b.DateFrom 
        WHERE a.DateFrom  = V_prevweekdate;
       -- order by 2
SET V_prevweekdate = DATEADD(hour, 1, V_prevweekdate)   

    ;
END WHILE;

-- [stub] WITH CTE AS (...); DELETE FROM CTE WHERE rn > 1 -- T-SQL dedupe pattern. Convert manually to QUALIFY ROW_NUMBER()=1 or MERGE WHEN MATCHED AND rn > 1 THEN DELETE.

-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_LastPrice;
DROP VIEW IF EXISTS TEMP_TABLE_price;
END;
