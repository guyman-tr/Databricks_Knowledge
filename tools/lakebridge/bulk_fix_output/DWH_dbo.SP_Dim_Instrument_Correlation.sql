USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation(
IN V_auxdate TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_date  TIMESTAMP
;
DECLARE V_row_count bigint;
DECLARE V_dateID INT ;
--EXEC [DWH_dbo].[SP_Dim_Instrument_Correlation] '2021-04-18'
/*IMPORTANT the reponsibility for the date of the run in on the user of this SP. 
e.g if you need quartertly covarience matrix make sure you put  int the write date */


/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table [DWH_dbo].Dim_Instrument_Correlation 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2025-
  
*********************************************************************************************/

set V_date= DATEADD(MONTH, -3, V_auxdate)
;
SET V_dateID = CAST(date_format(V_auxdate, 'yyyyMMdd') AS int)
;

DROP VIEW IF EXISTS TEMP_TABLE_data;
SELECT 'First Date of Q: '||date_format(V_date, 'yyyyMMdd')
;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_data AS select DateFrom ,InstrumentID ,cast((AskLast-AskFirst)/AskFirst as FLOAT) as PriceChange from dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted where DateFrom>=V_date and DateFrom<V_auxdate)
-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) delete from dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active where DateID = CAST(date_format(V_auxdate, 'yyyyMMdd') AS int)


-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
insert into dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active
(DateID,InstrumentID_a,InstrumentID_b,StandardDeviation_a,StandardDeviation_b,SampleSize,Covariance,PearsonCorrelation,InsertDate,UpdateDate)
select  
 CAST(date_format(V_auxdate, 'yyyyMMdd') AS int)
,InstrumentID_a
,InstrumentID_b
,STDEVP(PriceChange_a) as StandardDeviation_a
,STDEVP(PriceChange_b) as StandardDeviation_b
,count(*) as SampleSize
,cast(sum(PriceChange_a*PriceChange_b) as decimal(38,20))/count(*)-(cast(sum(PriceChange_a)*sum(PriceChange_b) as decimal(38,20)))/power(count(*),2.00) as Covariance
,(cast(sum(PriceChange_a*PriceChange_b) as decimal(38,20))/count(*)-(cast(sum(PriceChange_a)*sum(PriceChange_b) as decimal(38,20)))/power(count(*),2.00))/nullif(cast(STDEVP(PriceChange_a)*STDEVP(PriceChange_b) as decimal(38,20)),0) as PearsonCorrelation
, current_timestamp() AS InsertDate
, current_timestamp() AS UpdateDate
from 
(
select a.DateFrom,a.InstrumentID as InstrumentID_a,b.InstrumentID as InstrumentID_b ,a.PriceChange as PriceChange_a,b.PriceChange as PriceChange_b
 from TEMP_TABLE_data a join TEMP_TABLE_data b on(a.DateFrom=b.DateFrom)
  WHERE a.InstrumentID <= b.InstrumentID
) k
group by InstrumentID_a,InstrumentID_b
having  STDEVP(PriceChange_a)>0 AND  STDEVP(PriceChange_b)>0

;

-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
--SELECT @row_count
--PRINT @row_count

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_data;
END;
