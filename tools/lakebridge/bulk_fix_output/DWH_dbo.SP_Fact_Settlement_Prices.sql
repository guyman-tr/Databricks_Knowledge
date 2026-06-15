USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Settlement_Prices(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
/********************************************************************************************
Author: Inbal BML   
Date: 2024-10-31       
Description: 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

  
*********************************************************************************************/
-- EXEC [DWH_dbo].[SP_Fact_Settlement_Prices] '2024-12-10'
--declare @dt as date = '2024-11-02'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
----------------------------- delete rows --------------------------

  DELETE FROM dwh_daily_process.migration_tables.Fact_Settlement_Prices
  WHERE SettlementDate >= V_Yesterday
  and SettlementDate < V_CurrentDate;
--------------------------------------------------------------------
 INSERT INTO dwh_daily_process.migration_tables.Fact_Settlement_Prices
           (`InstrumentID`
		   ,`SettlementDateID`
           ,`SettlementDate`
           ,`SettlementPrice`
		   ,`UpdateDate`)
 SELECT 
      InstrumentID
	 ,CAST(date_format(DATEADD(day, DATEDIFF(0, Date), 0), 'yyyyMMdd') AS int) as SettlementDateID
     ,Date as SettlementDate
     ,Price as SettlementPrice
	 , current_timestamp() as UpdateDate
 from dwh_daily_process.daily_snapshot.EndOfDay_EOD_SettlementPrices
 WHERE Date >= V_Yesterday and Date < V_CurrentDate

;
END;
