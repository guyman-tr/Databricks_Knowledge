USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_MaxDateDim_PositionHedgeServerChangeLog_Snapshot  TIMESTAMP
;
DECLARE V_YesterdayID int ;

DECLARE V_CurrentDateID int;
-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-09-19
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse] 
-- =============================================

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
SET V_YesterdayID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;
SET V_CurrentDateID = CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS int);
------------get max date Dim_PositionHedgeServerChangeLog_Snapshot-------------------------------------

SET V_MaxDateDim_PositionHedgeServerChangeLog_Snapshot = (
SELECT
COALESCE()(max(convert(TIMESTAMP,CAST(from dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
/*------ Delete Rows ----------------------------*/
LIMIT 1 AS STRING)
IF V_Yesterday<=V_MaxDateDim_PositionHedgeServerChangeLog_Snapshot
 THEN
	DELETE FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
	WHERE FromDate>= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
 
END IF

  
 ------ Update DateRangeID ----------------------------
DROP VIEW IF EXISTS TEMP_TABLE_Dim_PositionHedgeServerChangeLog_Snapshot_UpdateToDate

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Dim_PositionHedgeServerChangeLog_Snapshot_UpdateToDate AS
SELECT PositionID,FromDate, ToDate, ROW_NUMBER() OVER (PARTITION BY PositionID ORDER BY FromDate DESC)  AS rn

FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot


MERGE INTO dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot a
INNER JOIN TEMP_TABLE_Dim_PositionHedgeServerChangeLog_Snapshot_UpdateToDate b ON a.PositionID = b.PositionID AND b.FromDate = a.FromDate

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
ToDate = 20991231
TRUNCATE TABLE  dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog
 
 
-------- Extract Ext_Dim_Position_PositionHedgeServerChangeLog -------------------

	INSERT INTO  dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog
	(	PositionID	,
		OccurredDate,  
		OccurredDateID,
		FromHedgeServerID,	
		ToHedgeServerID, 
		UpdateDate)
	SELECT 
	PositionID	,
	ADM_DATE as OccurredDate,  
	cast(date_format(ADM_DATE, 'yyyyMMdd') AS INT) as OccurredDateID,
	FromHedgeServerID,	
	ToHedgeServerID, 
	current_timestamp() as UpdateDate
	from dwh_daily_process.daily_snapshot.etoro_Trade_PositionsHedgeServerChangeLog
	where ADM_DATE >= DATEADD(HOUR, -1, V_Yesterday)  and ADM_DATE  < DATEADD(day, DATEDIFF(-1, V_Yesterday), 0)




-- Insert from [DWH_dbo].[Dim_PositionChangeLog]  ------------

call dwh_daily_process.migration_tables.SP_Dim_Position_PositionHedgeServerChangeLog(V_Yesterday)
END
