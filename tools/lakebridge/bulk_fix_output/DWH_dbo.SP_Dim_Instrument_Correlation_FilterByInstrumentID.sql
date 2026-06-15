USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_FilterByInstrumentID(
IN V_auxdate TIMESTAMP,
IN V_GroupID int,
IN V_TableID int,
IN V_WithDelete int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


 

DECLARE V_date  TIMESTAMP
;
DECLARE V_row_count bigint;
DECLARE V_FromInstrumentID INT
;
DECLARE V_ToInstrumentID INT
;
DECLARE V_SQL STRING
;
DECLARE V_dateID INT ;
/********************************************************************************************
Author:      Eitan Lipovetsky
Date:        2025-01-26
Description: Update table [DWH_dbo].SP_Dim_Instrument_Correlation_FilterByInstrumentID
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
   
*********************************************************************************************/

set V_date= DATEADD(MONTH, -3, V_auxdate)
;
SET V_dateID = CAST(date_format(V_auxdate, 'yyyyMMdd') AS int)
;

DROP VIEW IF EXISTS TEMP_TABLE_data;
SELECT 'First Date of Q: '||date_format(V_date, 'yyyyMMdd')
;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) SET V_SQL=' SELECT DateFrom,InstrumentID ,cast((AskLast-AskFirst)/AskFirst as FLOAT) as PriceChange from dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted where DateFrom>="'||date_format(V_date, 'yyyy-MM-dd hh:mm:ss:SSS ||'" and DateFrom<"'||date_format(V_auxdate, 'yyyy-MM-dd hh:mm:ss:SSS||'" ')
EXECUTE IMMEDIATE V_SQL

;
SET V_FromInstrumentID = (
SELECT
MinInstrumentID FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments
 WHERE GroupID=V_GroupID

 

------------------create clustered index IX_datefrom on #data(InstrumentID) with (data_compression =page)

------------------select * into #data2 from #data

------------------create clustered index IX_datefrom2 on #data2(InstrumentID) with (data_compression =page)
 LIMIT 1);
SET V_ToInstrumentID = (
SELECT
MaxInstrumentID FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments
 WHERE GroupID=V_GroupID

 

------------------create clustered index IX_datefrom on #data(InstrumentID) with (data_compression =page)

------------------select * into #data2 from #data

------------------create clustered index IX_datefrom2 on #data2(InstrumentID) with (data_compression =page)
 LIMIT 1);
-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
IF V_WithDelete=1
THEN
/*delete all rows for specific date befor insert*/

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
SET V_SQL='delete from dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Half_Records_'||CAST(V_TableID AS STRING)||' where DateID = ' || CAST(CAST(date_format(V_auxdate, 'yyyyMMdd') AS int) AS STRING) ||''
	;
EXECUTE IMMEDIATE V_SQL
;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END IF;
/*----------------------------------------------*/
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
SET V_SQL=';
insert into dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Half_Records_'||CAST(V_TableID  AS STRING)||'(DateID,InstrumentID_a,InstrumentID_b,StandardDeviation_a,StandardDeviation_b,SampleSize,Covariance,PearsonCorrelation,InsertDate,UpdateDate)
select  
 '||CAST(CAST(date_format(V_auxdate, 'yyyyMMdd') AS int) AS STRING) ||' as DateID
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
  AND a.InstrumentID BETWEEN '||CAST(V_FromInstrumentID AS STRING)||' AND '||CAST(V_ToInstrumentID AS STRING)||' 
) k
group by InstrumentID_a,InstrumentID_b
having  STDEVP(PriceChange_a)>0 AND  STDEVP(PriceChange_b)>0

'
;
EXECUTE IMMEDIATE V_SQL
;

-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END;
