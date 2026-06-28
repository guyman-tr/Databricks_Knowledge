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
	and CloseDateID = CAST(date_format(DATEADD(day, -1, current_date()), 'yyyyMMdd') AS int))
	and IsReOpen =1;

	--- Add Indication For PositionID that do Partial Close after ReOpen 
	UPDATE dwh_daily_process.migration_tables.Dim_Position
SET IsPartialCloseChildFromReOpen = 1
WHERE PositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen);
	UPDATE dwh_daily_process.migration_tables.Dim_Position
SET IsPartialCloseChildFromReOpen = 1,
    CommissionOnCloseOrig = CommissionOnClose,
    FullCommissionOnCloseOrig = FullCommissionOnClose
WHERE OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen);
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
UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT
SET CommissionOnClose = (
      SELECT b.CommissionOnClose - c.CommissionOnClose * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)
      FROM TEMP_TABLE_ReopenForPosition b
      INNER JOIN TEMP_TABLE_PositionOrigin c ON b.ReopenForPositionID = c.PositionID
      WHERE b.PositionID = a_TGT.PositionID
      LIMIT 1
    ),
    FullCommissionOnClose = (
      SELECT b.FullCommissionOnClose - c.FullCommissionOnClose * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)
      FROM TEMP_TABLE_ReopenForPosition b
      INNER JOIN TEMP_TABLE_PositionOrigin c ON b.ReopenForPositionID = c.PositionID
      WHERE b.PositionID = a_TGT.PositionID
      LIMIT 1
    )
WHERE EXISTS (
      SELECT 1
      FROM TEMP_TABLE_ReopenForPosition b
      WHERE b.PositionID = a_TGT.PositionID
    );
UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT
SET CommissionOnClose = a_TGT.CommissionOnCloseOrig - (
      SELECT e.CommissionOnClose
      FROM dwh_daily_process.migration_tables.Dim_Position c
      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID
      WHERE c.PositionID = a_TGT.OriginalPositionID
      LIMIT 1
    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits),
    FullCommissionOnClose = a_TGT.FullCommissionOnCloseOrig - (
      SELECT e.FullCommissionOnClose
      FROM dwh_daily_process.migration_tables.Dim_Position c
      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID
      WHERE c.PositionID = a_TGT.OriginalPositionID
      LIMIT 1
    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)
WHERE a_TGT.CloseOccurred <> '1900-01-01 00:00:00.000'
  AND a_TGT.OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen);
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_IsPartialCloseChildFromReOpen;
DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;
DROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;
END