USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_PositionHedgeServerChangeLog_backup_20210621(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_dateID int  ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-11-16
Description: Data for Dim_PositionHedgeServerChangeLog
 
**************************
** Change History
**************************
Date             Author       Description  
----------     ----------   ------------------------------------
 
*********************************************************************************************/


--declare @date date = cast(getdate()-1 as date)

SET V_dateID = cast(date_format(V_date, 'yyyyMMdd') AS INT);
-- list of PositionID
--drop table if exists #PositionID

DROP VIEW IF EXISTS TEMP_TABLE_PositionID;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionID AS
Select Distinct PositionID

from dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog
where OccurredDateID>=V_dateID;

 --Create Clustered index #PositionID on #PositionID(PositionID)

-- tale all data for relevant PositionID
--drop table if exists #PositionHedgeServerChangeLog
DROP VIEW IF EXISTS TEMP_TABLE_PositionHedgeServerChangeLog;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionHedgeServerChangeLog AS
Select a.*

from dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog a
join TEMP_TABLE_PositionID b
on a.PositionID = b.PositionID;

 --Create Clustered index #PositionHedgeServerChangeLog on #PositionHedgeServerChangeLog(PositionID)

--Calculate all data (include historical data) for relevant Positions
--drop table if exists #FinalData
DROP VIEW IF EXISTS TEMP_TABLE_FinalData;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_FinalData AS
SELECT a.PositionID  , FromHedgeServerID as HedgeServerID
, b.OpenDateID as FromDate
, cast(date_format(cast(DATEADD(day, -1, OccurredDate) as date), 'yyyyMMdd') AS INT) as ToDate
, current_timestamp() UpdateDate

FROM
(
select PositionID, OccurredDate, FromHedgeServerID, row_number() over (partition by PositionID order by OccurredDate) rn
FROM TEMP_TABLE_PositionHedgeServerChangeLog a
) a
join dwh_daily_process.migration_tables.Dim_Position b on a.PositionID = b.PositionID
where a.rn=1
union
SELECT PositionID  
, ToHedgeServerID as HedgeServerID
, cast(date_format(cast(OccurredDate as date), 'yyyyMMdd') AS INT) as FromDate
, cast(date_format(DATEADD(day, -1, LEAD(cast(OccurredDate as date), 1, '2099-12-31') OVER (PARTITION BY PositionID ORDER BY OccurredDate)), 'yyyyMMdd') AS INT) as ToDate
, current_timestamp() UpdateDate
FROM TEMP_TABLE_PositionHedgeServerChangeLog;

-- Delete all rows
 
MERGE INTO dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog a_tgt
USING (
select *   
FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog a 
INNER JOIN TEMP_TABLE_PositionID b on a.PositionID = b.PositionID  

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)   ON a.PositionID = a_tgt.PositionID
WHEN MATCHED THEN DELETE ;
insert into dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog
(
`PositionID`
           ,`HedgeServerID`
           ,`FromDate`
           ,`ToDate`
           ,`UpdateDate`
  )
select `PositionID`
           ,`HedgeServerID`
           ,`FromDate`
           ,`ToDate`
           ,`UpdateDate` from TEMP_TABLE_FinalData


;
END;
