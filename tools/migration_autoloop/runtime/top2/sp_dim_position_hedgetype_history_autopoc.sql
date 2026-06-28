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
SELECT p.PositionID,
       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID
WHERE p.OpenDateID < V_datnexteid
  AND p.CloseDateID = V_dateid
QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1
) s
ON s.PositionID = p_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
EndHedgeType = s.EndHedgeType;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT p.PositionID,
       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType,
       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID
WHERE p.OpenDateID >= V_dateid
  AND p.CloseDateID = V_dateid
QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1
) s
ON s.PositionID = p_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
InitHedgeType = s.InitHedgeType,
EndHedgeType = s.EndHedgeType;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT
USING (
SELECT p.PositionID,
       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID
WHERE p.OpenDateID >= V_dateid
  AND p.CloseDateID > V_dateid
QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1
) s
ON s.PositionID = p_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
InitHedgeType = s.InitHedgeType;
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
END