BEGIN


DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: <2021-09-13>
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Fact_Guru_Copiers_DL_To_Synapse]
-- =============================================

set V_Yesterday= cast(V_dt as TIMESTAMP) ;
set V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Fact_Guru_Copiers ----
	-- SELECT
	--[IndRun],
	--[IndRunRollToToday]
	--  FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
	--  where [TableName] = 'Fact_Guru_Copiers'
----------------------------------------------------
-- Delete Rows - Fact_Guru_Copiers -----------------

	Delete
	from dwh_daily_process.migration_tables.Fact_Guru_Copiers 
	where
	DateID >= cast(date_format(cast(V_Yesterday as date), 'yyyyMMdd') as INT)
	and
	DateID < cast(date_format(cast(V_CurrentDate as date), 'yyyyMMdd') as INT);
----------------------------------------------------
-- Extract Fact_Guru_Copiers -----------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FGC_Guru_Copiers
	SELECT   
	     `CID`
		,`ParentCID`
		,`ParentUserName`
		,`Occurred`
		,CAST(date_format(TIMESTAMP, 'yyyyMMdd') AS int) DateID
		,`StartCopy`
		,cast(`Cash` as decimal(18,4))
		,cast(`Investment` as decimal(18,4))
		,cast(`PnL` as decimal(18,4))
		,cast(`DetachedPosInvestment` as decimal(18,4))
		,cast(`Dit_PnL` as decimal(18,4))
	FROM dwh_daily_process.daily_snapshot.etoro_History_GuruCopiers
	WHERE TIMESTAMP = V_Yesterday;
----------------------------------------------------
-- Execute SP_Fact_Guru_Copiers --------------------
call dwh_daily_process.migration_tables.SP_Fact_Guru_Copiers(V_Yesterday);
END