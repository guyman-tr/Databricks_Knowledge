BEGIN

	
DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Single_cnt int ;
--DECLARE @dt as [Date] = '2021-01-01'

SET V_Yesterday= CAST(V_dt as TIMESTAMP) ;
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Fact_MarketPageViews -----
	--SELECT
 --    [IndRun]
 -- FROM pagetracking.[DataSolutionsTablesRunInd]
 -- where [TableName] = 'Fact_MarketPageViews'
--------------------------------------------------------
-- SP_Fact_MarketPageViews_Create_SWITCH_SINGLE --------

call dwh_daily_process.migration_tables.SP_Fact_MarketPageViews_Create_SWITCH_SINGLE();
TRUNCATE table dwh_daily_process.migration_tables.Ext_MarketPageViews;
--------------------------------------------------------
-- Prepre global TMP for IDs ---------------------------
--DECLARE @dt as [Date] = '2021-01-01'
DROP VIEW IF EXISTS TEMP_TABLE_ALL_IDs ;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ALL_IDs  
	AS
	SELECT
		MarketPageViewID
	FROM dwh_daily_process.daily_snapshot.tracking_Tracking_MarketPageViews 
	--Tracking.MarketPageViews
	WHERE Occurred>= V_Yesterday
	AND Occurred < V_CurrentDate
	;
--------------------------------------------------------
-- Prepare Ext ------------------------------------------

	insert into dwh_daily_process.migration_tables.Ext_MarketPageViews
	(
	  `MarketPageViewID` 
	 ,`CID`
	 ,`Occurred`
	 ,`InstrumentID` 
	 ,`SourceID`
	 ,`UpdateDate`
	)
	select 
		MPV.MarketPageViewID
		--,Convert(BIGINT, Identifier) as GCID
		,CAST(I.CID AS BIGINT)  as CID
		,MPV.Occurred
		,MPV.InstrumentID
		,MPV.SourceID
		,current_timestamp() UpdateDate
	from dwh_daily_process.daily_snapshot.tracking_Tracking_MarketPageViews MPV  
	join dwh_daily_process.migration_tables.TrackingIDs I on I.`Identifier`= MPV.`Identifier`
	where MPV.MarketPageViewID 
		in (select MarketPageViewID from TEMP_TABLE_ALL_IDs);
--------------------------------------------------------
-- MOVE To Fact ----------------------------------------
	insert into dwh_daily_process.migration_tables.Fact_MarketPageViews_SWITCH_SINGLE
	(
	  `RealCID`
	 ,`MarketPageViewID` 
	 ,`InstrumentID`
	 ,`SourceID`
	 ,`Occurred`
	 ,`DateID` 
	 ,`UpdateDate`
	)
	SELECT 
	   `CID` RealCID
      ,`MarketPageViewID`
      ,`InstrumentID`
      ,`SourceID`
      ,`Occurred`
      ,cast(date_format(`Occurred`, 'yyyyMMdd') AS INT) DateID
       ,current_timestamp() UpdateDate
  FROM dwh_daily_process.migration_tables.Ext_MarketPageViews;

--------------------------------------------------------
-- SP_Fact_MarketPageViews_SWITCH ----------------------
SET V_Single_cnt = (select count(1)
from  dwh_daily_process.migration_tables.Fact_MarketPageViews_SWITCH_SINGLE )
;
IF V_Single_cnt >0
	THEN
call dwh_daily_process.migration_tables.SP_Fact_MarketPageViews_SWITCH();
ELSE


		  select  1
	;
END IF;
	/* this if was created to  avoid exec when  no records were loaded to the single table  */
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_ALL_IDs;
END