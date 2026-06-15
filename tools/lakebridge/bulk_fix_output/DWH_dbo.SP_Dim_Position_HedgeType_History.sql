USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_HedgeType_History(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_dateid  INT
;
DECLARE V_datnexteid  INT
;
DECLARE V_MinOpenDateID int
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2021-07-11
Description: Update table Dim_Position
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2023-05-07     Boris.P        Optimize InitHedgeType Update statements 
*********************************************************************************************/
--declare @date as datetime = Cast(getdate() - 1 as date)
--EXEC [DWH_dbo].[SP_Dim_Position_HedgeType_History] @date

set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int)
;
set V_datnexteid=cast(date_format(DATEADD(day, 1, V_date), 'yyyyMMdd') AS INT)  

;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID
)
ON OpenDateID < V_datnexteid AND CloseDateID = V_dateid AND 
COALESCE(p.EndExecutionID::string,'__NULL__') = COALESCE(p_TGT.EndExecutionID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
EndHedgeType = CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID
)
ON OpenDateID >= V_dateid AND CloseDateID = V_dateid AND 
COALESCE(p.InitExecutionID::string,'__NULL__') = COALESCE(p_TGT.InitExecutionID::string,'__NULL__') AND 
COALESCE(p.EndExecutionID::string,'__NULL__') = COALESCE(p_TGT.EndExecutionID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
InitHedgeType = CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END ,
EndHedgeType = CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID
)
ON OpenDateID >= V_dateid AND CloseDateID > V_dateid AND 
COALESCE(p.InitExecutionID::string,'__NULL__') = COALESCE(p_TGT.InitExecutionID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
InitHedgeType = CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;
set V_MinOpenDateID = (select min(OpenDateID) from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real);

--UPDATE p
--SET
--InitHedgeType = ap.InitHedgeType
--from [DWH_dbo].Ext_Dim_Position_History_Real p
--join [DWH_dbo].Dim_Position ap
--on p.OriginalPositionID = ap.PositionID
--Where p.OriginalPositionID <> p.PositionID
--and ap.OpenDateID>=@MinOpenDateID

--UPDATE p
--SET
--InitHedgeType = ap.InitHedgeType
--from [DWH_dbo].Ext_Dim_Position_History_Real p
--join [DWH_dbo].Dim_Position ap
--on p.ReopenForPositionID = ap.PositionID
--Where p.ReopenForPositionID <> p.PositionID
--AND p.IsReOpen = 1
--and ap.OpenDateID>=@MinOpenDateID
DROP VIEW IF EXISTS TEMP_TABLE_pos ;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_pos  
    
AS 
SELECT ap.InitHedgeType ,ap.PositionID  from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p  
JOIN dwh_daily_process.migration_tables.Dim_Position ap  on p.OriginalPositionID = ap.PositionID  
WHERE p.OriginalPositionID <> p.PositionID  
and ap.OpenDateID>= V_MinOpenDateID;


MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
INNER JOIN TEMP_TABLE_pos ap on p.OriginalPositionID = ap.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY p.OriginalPositionID ORDER BY 1) = 1
)
ON p.OriginalPositionID = p_TGT.OriginalPositionID
WHEN MATCHED THEN UPDATE SET
InitHedgeType = ap.InitHedgeType;
DROP VIEW IF EXISTS TEMP_TABLE_pos2 ;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_pos2  
    
AS 
SELECT ap.InitHedgeType ,ap.PositionID  from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p  
JOIN dwh_daily_process.migration_tables.Dim_Position ap  on p.OriginalPositionID = ap.PositionID  
Where p.ReopenForPositionID <> p.PositionID  
AND p.IsReOpen = 1  and ap.OpenDateID>= V_MinOpenDateID;

MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
INNER JOIN TEMP_TABLE_pos2 ap on p.ReopenForPositionID = ap.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY p.ReopenForPositionID ORDER BY 1) = 1
)
ON p.ReopenForPositionID = p_TGT.ReopenForPositionID
WHEN MATCHED THEN UPDATE SET
InitHedgeType = ap.InitHedgeType;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_pos;
DROP VIEW IF EXISTS TEMP_TABLE_pos2;
END;
