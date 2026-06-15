USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerAction_IsParitalCloseParent(
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
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OriginalPositionID  
 AS
select distinct OriginalPositionID
from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
where
PositionID <> OriginalPositionID 
AND ActionTypeID in (4,5,6,28,40);


SET V_DateMin = (SELECT CAST(date_format(min(OpenOccurred), 'yyyyMMdd') AS int)  FROM  dwh_daily_process.migration_tables.Ext_FCA_History_Position)
;
MERGE INTO dwh_daily_process.migration_tables.Fact_CustomerAction a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Fact_CustomerAction a
INNER JOIN TEMP_TABLE_OriginalPositionID b on a.PositionID = b.OriginalPositionID --Changed by Boris Pinsky on 2022-02-07
 --"Where" filters were moved to case for better performance (Yes , It's strange... ) 
 --Update a
 --set 
 --IsPartialCloseParent = 1
 --from [DWH_dbo].Fact_CustomerAction a
 --join #OriginalPositionID b
 --on a.PositionID = b.OriginalPositionID 
 --AND ActionTypeID in (1,2,3,39)
 --and a.DateID >=@DateMin


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
--IsPartialCloseParent = 1
 IsPartialCloseParent = CASE WHEN a.ActionTypeID in ( 1 , 2 , 3 , 39 ) AND a.DateID >= V_DateMin THEN 1 ELSE a.IsPartialCloseParent END;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_OriginalPositionID;
END;
