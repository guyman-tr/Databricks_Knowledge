USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_PositionHedgeServerChangeLog(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_dateID int  ;

DECLARE V_dateprev date ;

DECLARE V_dateIDprev int  ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-11-16
Description: Data for Dim_PositionHedgeServerChangeLog
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2022-04-26    Boris          Syns SPbetween two Env (DWH-01 to Synapse)
*********************************************************************************************/

--declare @date date = cast(getdate()-1 as date)

SET V_dateID = cast(date_format(V_date, 'yyyyMMdd') AS INT)
;
SET V_dateprev = DATEADD(DAY, -1, V_date)
;
SET V_dateIDprev = cast(date_format(V_dateprev, 'yyyyMMdd') AS INT);
--------Truncate table [DWH_dbo].Ext_Dim_Position_PositionHedgeServerChangeLog 
--------INSERT iNTO [DWH_dbo].Ext_Dim_Position_PositionHedgeServerChangeLog
--------select
--------PositionID ,
--------ADM_DATE as OccurredDate,  
--------cast(CONVERT (VARCHAR(8) , ADM_DATE, 112 ) AS INT) as OccurredDateID,
--------FromHedgeServerID,
--------ToHedgeServerID,
--------getdate() as UpdateDate
--------from [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.PositionsHedgeServerChangeLog  
--------where ADM_DATE>=@date and ADM_DATE<dateadd(day, 1, @date)
--------;
-- [stub] WITH CTE AS (...); DELETE FROM CTE WHERE rn > 1 -- T-SQL dedupe pattern. Convert manually to QUALIFY ROW_NUMBER()=1 or MERGE WHEN MATCHED AND rn > 1 THEN DELETE.

DROP VIEW IF EXISTS TEMP_TABLE_PositionHedgeServerChangeLog;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionHedgeServerChangeLog AS
SELECT DISTINCT a.PositionID

FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot AS a
JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog AS b
ON a.PositionID=b.PositionID
WHERE ToDate=20991231 
;
MERGE INTO dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot a
INNER JOIN TEMP_TABLE_PositionHedgeServerChangeLog b ON a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
ToDate = V_dateIDprev ,
UpdateDate = current_timestamp();
INSERT INTO  dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
(PositionID	,HedgeServerID	,FromDate,	ToDate	,UpdateDate	)
SELECT		a.PositionID	,ToHedgeServerID	,V_dateID,	20991231	,current_timestamp()
FROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog a
JOIN TEMP_TABLE_PositionHedgeServerChangeLog b
ON a.PositionID = b.PositionID;

--- Find OpenDateID for Intial Change of Hedge
DROP VIEW IF EXISTS TEMP_TABLE_NewPositions;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_NewPositions AS
SELECT b.*, c.OpenDateID

FROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog AS b
LEFT JOIN 
dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot AS a
on a.PositionID = b.PositionID
JOIN 
dwh_daily_process.migration_tables.Dim_Position AS c
on b.PositionID = c.PositionID -- AND c.OpenDateID>=@dateID
WHERE a.PositionID IS NULL;

-- Add a new position OpenDateID<OccurredDateID
INSERT INTO  dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
(PositionID, HedgeServerID, FromDate, ToDate, UpdateDate)
SELECT		
PositionID	,FromHedgeServerID	,
OpenDateID,
CAST(date_format(DATEADD(day, -1, CAST(OccurredDate AS DATE)), 'yyyyMMdd') AS INT),
current_timestamp()
FROM TEMP_TABLE_NewPositions
WHERE OpenDateID<OccurredDateID;

-- Add a new position OpenDateID<OccurredDateID --> Initial Row
INSERT INTO  dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
(PositionID, HedgeServerID, FromDate, ToDate, UpdateDate)
SELECT		
PositionID	,ToHedgeServerID	,
OccurredDateID,
20991231,
current_timestamp()
FROM TEMP_TABLE_NewPositions;
------WHERE OpenDateID<OccurredDateID


-------- Add a new position OpenDateID<OccurredDateID --> First Change
------INSERT INTO  [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
------(PositionID, HedgeServerID, FromDate, ToDate, UpdateDate)
------SELECT		
------PositionID	,ToHedgeServerID,
------OpenDateID,
------20991231,
------GETDATE()
------FROM #NewPositions
------WHERE OpenDateID=OccurredDateID
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_NewPositions;
DROP VIEW IF EXISTS TEMP_TABLE_PositionHedgeServerChangeLog;
END;
