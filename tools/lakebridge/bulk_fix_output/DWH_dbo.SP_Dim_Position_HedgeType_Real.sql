USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_HedgeType_Real(
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
/********************************************************************************************
Author:      Boris Slutski
Date:        2021-07-11
Description: Update table Dim_Position
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/
--declare @date as datetime = Cast(getdate() - 1 as date)
--EXEC [DWH_dbo].[SP_Dim_Position_HedgeType_Real] @date

set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int)
;
set V_datnexteid=cast(date_format(DATEADD(day, 1, V_date), 'yyyyMMdd') AS INT)  
;
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real p_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_Dim_Position_Real p
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID
)
ON OpenDateID >= V_dateid AND 
COALESCE(p.InitExecutionID::string,'__NULL__') = COALESCE(p_TGT.InitExecutionID::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
InitHedgeType = CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;
END;
