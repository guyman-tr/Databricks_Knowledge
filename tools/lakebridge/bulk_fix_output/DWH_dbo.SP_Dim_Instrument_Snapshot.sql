USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Snapshot(
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
DECLARE V_Tomorrow  TIMESTAMP
;
DECLARE V_Yesterdayint  int ;

DECLARE V_CurrentDateint  int ;

DECLARE V_Tomorrowint  int ;
/********************************************************************************************
Author: Inbal BML   
Date: 2024-10-31       
Description: daily Snapshot of Dim_Instrument table
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

  
*********************************************************************************************/
-- EXEC [DWH_dbo].[SP_Dim_Instrument_Snapshot] '2024-11-06'
--declare @dt as date = '2024-12-02'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday)
  ;
SET V_Tomorrow = DATEADD(DAY, 2, V_Yesterday)
  ;
SET V_Yesterdayint = CAST(date_format(DATEADD(day, DATEDIFF(0, V_Yesterday), 0), 'yyyyMMdd') AS int) 
;
SET V_CurrentDateint = CAST(date_format(DATEADD(day, DATEDIFF(0, V_CurrentDate), 0), 'yyyyMMdd') AS int)
;
SET V_Tomorrowint = CAST(date_format(DATEADD(day, DATEDIFF(0, V_Tomorrow), 0), 'yyyyMMdd') AS int);
----------------------------- delete rows --------------------------
  DELETE FROM dwh_daily_process.migration_tables.Dim_Instrument_Snapshot
  WHERE DateID >= V_Yesterdayint
  and DateID < V_CurrentDateint;
--------------------------------------------------------------------
INSERT INTO dwh_daily_process.migration_tables.Dim_Instrument_Snapshot
           (`DateID`
           ,`InstrumentID`
		   ,`Multiplier`
		   ,`ProviderID`
		   ,`ProviderMarginPerLot`
		   ,`eToroMarginPerLot`
		   ,`SettlementTime`
		   ,`IsFuture`
		   ,`UpdateDate`
		   )

SELECT 	   V_Yesterdayint as DateID 
		  , InstrumentID 
		  , Multiplier
	 	  , ProviderID
		  , ProviderMarginPerLot
		  , eToroMarginPerLot
		  , CAST(date_format(V_dt, 'yyyyMMdd')  || ' ' || date_format(SettlementTime, 'hh:mm:ss') AS TIMESTAMP) as SettlementDateTime
		  , IsFuture
		  , current_timestamp() as UpdateDate
from dwh_daily_process.migration_tables.Dim_Instrument 

;
END;
