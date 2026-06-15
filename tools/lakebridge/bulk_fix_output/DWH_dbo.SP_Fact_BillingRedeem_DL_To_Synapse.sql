USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_BillingRedeem_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_From  TIMESTAMP
;
SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
SET V_From = DATEADD(DAY, -7, V_Yesterday);

  -- Select Parameter Run Ind - Fact_BillingRedeem -------------------
	--SELECT
	-- [IndRun]
	--FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
	--WHERE [TableName] = 'Fact_BillingRedeem'
--------------------------------------------------------------------
-- Delete rows from Fact_BillingRedeem -----------------------------
	DELETE FROM dwh_daily_process.migration_tables.Fact_BillingRedeem
	WHERE
	ModificationDateID >= CAST(date_format(V_From, 'yyyyMMdd') AS int)
	AND
	ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS int);
--------------------------------------------------------------------
-- Truncate Ext_FBR_Fact_BillingRedeem -----------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FBR_Fact_BillingRedeem;
--------------------------------------------------------------------
-- Extract Ext_Fact_BillingRedeem ----------------------------------
	INSERT INTO dwh_daily_process.migration_tables.Ext_FBR_Fact_BillingRedeem
	(
		   CID
	  , RedeemID
	   ,PositionID
	   ,RedeemStatusID
	   ,RedeemReasonID
	   ,AmountOnRequest
	   ,AmountOnClose
	   ,FundingID
	   ,RequestDate
	   ,LastModificationDate
	   ,ModificationDateID
	   ,UpdateDate
	)
	SELECT 
	   CID
	  , RedeemID
	   ,PositionID
	   ,RedeemStatusID
	   ,RedeemReasonID
	   ,AmountOnRequest
	   ,AmountOnClose
	   ,FundingID
	   ,RequestDate
	   ,LastModificationDate
	   ,CAST(date_format(DATEADD(day, DATEDIFF(0, LastModificationDate), 0), 'yyyyMMdd') AS int) as ModificationDateID
	   ,current_timestamp() as UpdateDate
	   FROM dwh_daily_process.daily_snapshot.etoro_Billing_Redeem
	WHERE
	LastModificationDate >= V_From AND LastModificationDate <DATEADD(day, 1, V_CurrentDate);
--------------------------------------------------------------------
-- Delete and Insert rows ------------------------------------------
  
MERGE INTO dwh_daily_process.migration_tables.Fact_BillingRedeem w_tgt 
USING (
select *   
FROM dwh_daily_process.migration_tables.Fact_BillingRedeem w  
INNER JOIN dwh_daily_process.migration_tables.Ext_FBR_Fact_BillingRedeem e  ON w.RedeemID=e.RedeemID  

QUALIFY ROW_NUMBER() OVER (PARTITION BY w.RedeemID ORDER BY 1) = 1
)   ON w.RedeemID = w_tgt.RedeemID
WHEN MATCHED THEN DELETE ;
	INSERT INTO dwh_daily_process.migration_tables.Fact_BillingRedeem
           (CID
	, RedeemID
	,PositionID
	,RedeemStatusID
	,RedeemReasonID
	,AmountOnRequest
	,AmountOnClose
	,FundingID
	,RequestDate
	,LastModificationDate
	,ModificationDateID
	, UpdateDate)
	     SELECT 
	 CID
	, RedeemID
	,PositionID
	,RedeemStatusID
	,RedeemReasonID
	,AmountOnRequest
	,AmountOnClose
	,FundingID
	,RequestDate
	,LastModificationDate
	,ModificationDateID
	,UpdateDate
	 FROM dwh_daily_process.migration_tables.Ext_FBR_Fact_BillingRedeem;
--------------------------------------------------------------------
-- Update The Process Finish to Ind 2 Fact_BillingRedeem -----------
	--UPDATE [DWH_dbo].[DataSolutionsTablesRunInd]
	--SET
	--[IndRun] = 2 ,
	--[UpdateDate] = GETDATE()
	--  where [TableName] = 'Fact_BillingRedeem'
	--AND [IndRun] <> 2 
--------------------------------------------------------------------
END;
