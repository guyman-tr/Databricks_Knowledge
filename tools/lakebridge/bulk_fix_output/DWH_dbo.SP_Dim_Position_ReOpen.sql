USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Position_ReOpen(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_dateid  int
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-11-11
Description: Update table Dim_Position
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/
	--declare @date as datetime = '20181230'

set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int);


	-- Fund PositionID Child that do Partial Close after ReOpen 
--DROP TABLE IF EXISTS #IsPartialCloseChildFromReOpen
DROP VIEW IF EXISTS TEMP_TABLE_IsPartialCloseChildFromReOpen;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_IsPartialCloseChildFromReOpen AS
select PositionID 
	
	from dwh_daily_process.migration_tables.Dim_Position  -- list of positon Reopen add do Partial Close for them
	where PositionID in 
	(
	select 
	 OriginalPositionID from  dwh_daily_process.migration_tables.Dim_Position
	where IsPartialCloseChild =1
	and CloseDateID = V_dateid)
	and IsReOpen =1;

	--- Add Indication For PositionID that do Partial Close after ReOpen 
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsPartialCloseChildFromReOpen = 1;
	MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on a.OriginalPositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.OriginalPositionID ORDER BY 1) = 1
)
ON a.OriginalPositionID = a_TGT.OriginalPositionID
WHEN MATCHED THEN UPDATE SET
IsPartialCloseChildFromReOpen = 1 ,
CommissionOnCloseOrig = a.CommissionOnClose ,
FullCommissionOnCloseOrig = a.FullCommissionOnClose;
DROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;
------------ #ReopenForPosition

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ReopenForPosition AS
select PositionID, ReopenForPositionID, CommissionOnClose,FullCommissionOnClose ,AmountInUnitsDecimal, InitialUnits
  -- postions IsReOpen =1 for update  fron Trade
from dwh_daily_process.migration_tables.Ext_Dim_Position_Real
where IsReOpen = 1

;
insert into TEMP_TABLE_ReopenForPosition
select PositionID, ReopenForPositionID, CommissionOnClose,FullCommissionOnClose ,AmountInUnitsDecimal, InitialUnits
from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real -- postions IsReOpen =1 for update  fron History
where IsReOpen = 1;

-- create CLUSTERED INdex #ReopenForPosition on #ReopenForPosition(PositionID)

--DROP TABLE IF EXISTS #PositionOrigin
DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionOrigin AS
SELECT a.PositionID, a.CommissionOnClose,a.FullCommissionOnClose
 -- Origin Commission 
from 
dwh_daily_process.migration_tables.Dim_Position  a join TEMP_TABLE_ReopenForPosition b 
on a.PositionID = b.ReopenForPositionID;

 --create CLUSTERED INdex #PositionOrigin on #PositionOrigin(PositionID)
MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN TEMP_TABLE_ReopenForPosition b on a.PositionID = b.PositionID -- postion for update 

INNER JOIN TEMP_TABLE_PositionOrigin c on b.ReopenForPositionID = c.PositionID -- data from origin position 


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
CommissionOnClose = b.CommissionOnClose - c.CommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits ) ,
FullCommissionOnClose = b.FullCommissionOnClose - c.FullCommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits );
 MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Position a
INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on b.PositionID = a.OriginalPositionID
INNER JOIN dwh_daily_process.migration_tables.Dim_Position c on a.OriginalPositionID = c.PositionID
INNER JOIN dwh_daily_process.migration_tables.Dim_Position e on e.PositionID = c.ReopenForPositionID
)
ON a.CloseOccurred <> '1900-01-01 00:00:00.000' AND 
COALESCE(a.CommissionOnCloseOrig::string,'__NULL__') = COALESCE(a_TGT.CommissionOnCloseOrig::string,'__NULL__') AND 
COALESCE(a.AmountInUnitsDecimal::string,'__NULL__') = COALESCE(a_TGT.AmountInUnitsDecimal::string,'__NULL__') AND 
COALESCE(a.InitialUnits::string,'__NULL__') = COALESCE(a_TGT.InitialUnits::string,'__NULL__') AND 
COALESCE(a.FullCommissionOnCloseOrig::string,'__NULL__') = COALESCE(a_TGT.FullCommissionOnCloseOrig::string,'__NULL__') AND 
COALESCE(a.OriginalPositionID::string,'__NULL__') = COALESCE(a_TGT.OriginalPositionID::string,'__NULL__') AND 
COALESCE(a.CloseOccurred::string,'__NULL__') = COALESCE(a_TGT.CloseOccurred::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
CommissionOnClose = a.CommissionOnCloseOrig - e.CommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits ) ,
FullCommissionOnClose = a.FullCommissionOnCloseOrig - e.FullCommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits );
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_IsPartialCloseChildFromReOpen;
DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;
DROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;
END;
