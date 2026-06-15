USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_IsPartialCloseParent(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_DateMin int ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-12-16
Description:
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/
--Drop table If Exists #OriginalPositionID

DROP VIEW IF EXISTS TEMP_TABLE_OriginalPositionID;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OriginalPositionID AS
select distinct OriginalPositionID

from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real
where
PositionID <> OriginalPositionID;

-- create clustered index #OriginalPositionID on #OriginalPositionID(OriginalPositionID)
SET V_DateMin = (SELECT CAST(date_format(min(OpenOccurred), 'yyyyMMdd') AS int)  from  dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real)
;
MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN TEMP_TABLE_OriginalPositionID b on a.PositionID = b.OriginalPositionID and a.OpenDateID >= V_DateMin

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsPartialCloseParent = 1;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_OriginalPositionID;
END;
