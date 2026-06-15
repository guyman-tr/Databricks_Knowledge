USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_GetSpreadedPriceUSDConversionRate_DeleteByDateRange(
IN V_dateStart TIMESTAMP,
IN V_dateEnd TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_nextdate  TIMESTAMP;
--DECLARE @prevweekdate as datetime
/*
    Deletes data from Dim_GetSpreadedPriceUSDConversionRate between the start and end date provided.
    Together with [DWH_dbo].SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour 
    it replaces [DWH_dbo].SP_Dim_GetSpreadedPriceUSDConversionRate.

    Usage:
    EXEC [DWH_dbo].[SP_Dim_GetSpreadedPriceUSDConversionRate_DeleteByDateRange] '2022-01-06 00:00:00', '2022-01-14 00:00:00'

*/

---DECLARE @date datetime =cast(cast(getdate()-1 as date) as datetime)

SET V_nextdate = DATEADD(day, 1, V_dateEnd);
--SET @prevweekdate = dateadd(week,-1,@date)
DELETE FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceUSDConversionRate
where `DateFrom` >= V_dateStart and `DateFrom` < V_nextdate
;
END;
