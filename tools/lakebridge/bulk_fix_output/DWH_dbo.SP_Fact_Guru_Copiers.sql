USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Guru_Copiers(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_dateID INT ;

DECLARE V_row_count INT 
;
--EXEC [DWH_dbo].[SP_Fact_Guru_Copiers] '2021-05-05'
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-05-15
Description: Insert in Fact_Guru_Copiers
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/

SET V_dateID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Fact_Guru_Copiers
           (`CID`
           ,`DateID`
           ,`Cash`
           ,`Investment`
           ,`PnL`
           ,`DetachedPosInvestment`
           ,`Dit_PnL`
           ,`CopyFundAUM`
		   ,`UpdateDate`)

	select g.CID
	, DateID
	,sum(COALESCE(Cash, 0)) as Cash
	,sum(COALESCE(Investment, 0)) as Investment
	,sum(COALESCE(PnL, 0)) as PnL
	,sum(COALESCE(DetachedPosInvestment, 0)) as DetachedPosInvestment
	,sum(COALESCE(Dit_PnL, 0)) as Dit_PnL
	,sum(COALESCE(Cash, 0))+sum(COALESCE(Investment, 0))+sum(COALESCE(PnL, 0))+sum(COALESCE(DetachedPosInvestment, 0))+sum(COALESCE(Dit_PnL, 0)) as CopyFundAUM
	,current_timestamp()
	from dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers g 
	Join dwh_daily_process.migration_tables.Fact_SnapshotCustomer fsc 
	on g.ParentCID = fsc.RealCID and fsc.AccountTypeID = 9
	join dwh_daily_process.migration_tables.V_M2M_Date_DateRange bb
	on(fsc.DateRangeID=bb.DateRangeID  and DateID = bb.DateKey)
	Group By g.CID,DateID
;
SET V_row_count = (
SELECT
COUNT(*) FROM dwh_daily_process.migration_tables.Fact_Guru_Copiers NOLOCK WHERE DateID = V_dateID
	 LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END;
