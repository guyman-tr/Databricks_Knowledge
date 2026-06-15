USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Mirror_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: 2021-09-05
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_Mirror_DL_To_Synapse] 
-- =============================================

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Dim_Mirror ---------
  --SELECT
  --   [IndRun]
  --FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
  --where [TableName] = 'Dim_Mirror'
--------------------------------------------------
-- Update Delete Rows ----------------------------

	delete from dwh_daily_process.migration_tables.Dim_Mirror 
	where OpenOccurred >= V_Yesterday and OpenOccurred < V_CurrentDate 
;
	Update dwh_daily_process.migration_tables.Dim_Mirror 
	set 
	CloseOccurred = '1900-01-01 00:00:00.000' ,
	CloseDateID = 0
	where CloseOccurred >= V_Yesterday and CloseOccurred < V_CurrentDate;
--------------------------------------------------
-- Extract Ext_Dim_Mirror_Real -------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real
	(
	   MirrorID
      ,CID
	  ,ParentCID
	  ,ParentUserName
	  ,Amount
	  ,OpenOccurred
	  ,OpenDateID
	  ,CloseOccurred
	  ,CloseDateID
	  ,MirrorTypeID
	  ,CloseMirrorActionType
	  ,IsActive
	  ,IsOpenOpen
	  ,PauseCopy
	  ,MirrorSL
	  ,MirrorSLPercentage
	  ,RealizedEquity
	  ,InitialInvestment
	  ,WithdrawalSummary
	  ,DepositSummary
	  ,RealziedPnL
      ,GuruTPV
      ,UseCopyDividend
	  )

	SELECT  
	   MirrorID
      ,CID
	  ,ParentCID
	  ,ParentUserName
	  ,Amount
	  ,Occurred as OpenOccurred
	  ,CAST(date_format(DATEADD(day, DATEDIFF(0, Occurred), 0), 'yyyyMMdd') AS int) as OpenDateID
	  ,cast(0 as TIMESTAMP) as CloseOccurred
	  ,0 As CloseDateID
	  ,MirrorTypeID
	  ,CloseMirrorActionType
	  ,CAST(IsActive AS INT)
	  ,IsOpenOpen
	  ,PauseCopy
	  ,MirrorSL
	  ,MirrorSLPercentage
	  ,RealizedEquity
	  ,InitialInvestment
	  ,WithdrawalSummary
	  ,DepositSummary
	  ,NetProfit as RealziedPnL
      ,GuruTPV
      ,UseCopyDividend
	  
	from dwh_daily_process.daily_snapshot.etoro_Trade_Mirror 
	where Occurred < V_CurrentDate;
--------------------------------------------------
-- Extract Ext_Dim_Mirror_History ----------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_Dim_Mirror_History

;
	insert into dwh_daily_process.migration_tables.Ext_Dim_Mirror_History
	(
	   MirrorID
      ,CID
	  ,ParentCID
	  ,ParentUserName
	  ,Amount
	  ,OpenOccurred
	  ,OpenDateID
	 	,CloseOccurred
	    ,CloseDateID
	  ,MirrorTypeID
	  ,CloseMirrorActionType
	  ,IsActive
	  ,IsOpenOpen
	  ,PauseCopy
	  ,MirrorSL
	  ,MirrorSLPercentage
	  ,RealizedEquity
	  ,InitialInvestment
	  ,WithdrawalSummary
	  ,DepositSummary
	  ,RealziedPnL
	  ,GuruTPV
	  ,UseCopyDividend
	)

	SELECT
	   MirrorID
      ,CID
	  ,ParentCID
	  ,ParentUserName
	  ,Amount
	  ,Occurred as OpenOccurred
	  ,CAST(date_format(DATEADD(day, DATEDIFF(0, Occurred), 0), 'yyyyMMdd') AS int) as OpenDateID
	 	,ModificationDate as CloseOccurred
	    ,CAST(date_format(DATEADD(day, DATEDIFF(0, ModificationDate), 0), 'yyyyMMdd') AS int)as CloseDateID
	  ,MirrorTypeID
	  ,CloseMirrorActionType
	  ,CAST(IsActive AS INT)
	  ,IsOpenOpen
	  ,PauseCopy
	  ,MirrorSL
	  ,MirrorSLPercentage
	  ,RealizedEquity
	  ,InitialInvestment
	  ,WithdrawalSummary
	  ,DepositSummary
	  ,NetProfit as RealziedPnL
	  ,GuruTPV
	  ,UseCopyDividend
	  
	from dwh_daily_process.daily_snapshot.etoro_History_Mirror 
	Where
	MirrorOperationID = 2 and 
		((
		ModificationDate >= V_Yesterday
		and 
	                   ModificationDate < V_CurrentDate
		)
	
	or
		(
		Occurred >= V_Yesterday
		and
		Occurred < V_CurrentDate
		and
	                  ModificationDate >= V_Yesterday
		));
	
--------------------------------------------------
-- Update from Ext_Dim_Mirror_History ------------
	MERGE INTO dwh_daily_process.migration_tables.Dim_Mirror A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Mirror a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Mirror_History b ON a.MirrorID = b.MirrorID and a.CloseDateID = 0 --------------------------------------------------
 -- Insert from Ext_Dim_Mirror_History ------------


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.MirrorID ORDER BY 1) = 1
)
ON a.MirrorID = A_TGT.MirrorID
WHEN MATCHED THEN UPDATE SET
Amount = b.Amount ,
OpenOccurred = b.OpenOccurred ,
OpenDateID = b.OpenDateID ,
CloseOccurred = b.CloseOccurred ,
CloseDateID = b.CloseDateID ,
MirrorTypeID = b.MirrorTypeID ,
CloseMirrorActionType = b.CloseMirrorActionType ,
IsActive = b.IsActive ,
IsOpenOpen = b.IsOpenOpen ,
PauseCopy = b.PauseCopy ,
MirrorSL = b.MirrorSL ,
MirrorSLPercentage = b.MirrorSLPercentage ,
RealizedEquity = b.RealizedEquity ,
InitialInvestment = b.InitialInvestment ,
WithdrawalSummary = b.WithdrawalSummary ,
DepositSummary = b.DepositSummary ,
RealziedPnL = b.RealziedPnL ,
GuruTPV = b.GuruTPV ,
UseCopyDividend = b.UseCopyDividend ,
UpdateDate = current_timestamp();
	INSERT INTO dwh_daily_process.migration_tables.Dim_Mirror
	           (`MirrorID`
	           ,`CID`
	           ,`ParentCID`
	           ,`ParentUserName`
	           ,`Amount`
	           ,`OpenOccurred`
	           ,`OpenDateID`
	           ,`CloseOccurred`
	           ,`CloseDateID`
	           ,`MirrorTypeID`
	           ,`CloseMirrorActionType`
	           ,`IsActive`
	           ,`IsOpenOpen`
	           ,`PauseCopy`
	           ,`MirrorSL`
	           ,`MirrorSLPercentage`
	           ,`RealizedEquity`
	           ,`InitialInvestment`
	           ,`WithdrawalSummary`
	           ,`DepositSummary`
	           ,`RealziedPnL`
	           ,`GuruTPV`
	           ,`UseCopyDividend`
			   ,`UpdateDate`)
	select  
	`MirrorID`
	,`CID`
	,`ParentCID`
	,`ParentUserName`
	,`Amount`
	,`OpenOccurred`
	,`OpenDateID`
	,case when CloseOccurred  >=cast(current_timestamp() as date) then '19000101' else CloseOccurred  end as CloseOccurred
	,case when CloseOccurred >=cast(current_timestamp() as date)  then 0 else CAST(date_format(DATEADD(day, DATEDIFF(0, CloseOccurred), 0), 'yyyyMMdd') AS int) end as CloseDateID
	--,[CloseOccurred]
	--,[CloseDateID]
	,`MirrorTypeID`
	,`CloseMirrorActionType`
	,`CAST(IsActive AS INT)`
	,`IsOpenOpen`
	,`PauseCopy`
	,`MirrorSL`
	,`MirrorSLPercentage`
	,`RealizedEquity`
	,`InitialInvestment`
	,`WithdrawalSummary`
	,`DepositSummary`
	,`RealziedPnL`
	,`GuruTPV`
	,`UseCopyDividend`
	,current_timestamp()
	from dwh_daily_process.migration_tables.Ext_Dim_Mirror_History
	where
	CloseDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int)
	and OpenDateID =  CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int);

--------------------------------------------------
-- Ext_Dim_Mirror_FundCIDs -----------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Mirror_FundCIDs

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_FundCIDs

	SELECT b.CID
	FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_Customer b 	
	WHERE b.AccountTypeID=9;
--------------------------------------------------
-- Update IsCopyFundMirror Ext_Dim_Mirror_Real ---
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Mirror_FundCIDs b ON a.ParentCID = b.CID --------------------------------------------------
 -- Update IsCopyFundMirror Ext_Dim_Mirror_History-


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.ParentCID ORDER BY 1) = 1
)
ON a.ParentCID = a_TGT.ParentCID
WHEN MATCHED THEN UPDATE SET
IsCopyFundMirror = 1;
	MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_History a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_Dim_Mirror_History a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Mirror_FundCIDs b ON a.ParentCID = b.CID --------------------------------------------------
 -- Remove Duplicate Mirrors ----------------------


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.ParentCID ORDER BY 1) = 1
)
ON a.ParentCID = a_TGT.ParentCID
WHEN MATCHED THEN UPDATE SET
IsCopyFundMirror = 1;
  
MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real a_tgt 
USING (
select *   
FROM   dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real a  
INNER JOIN  dwh_daily_process.migration_tables.Ext_Dim_Mirror_History b  ON  a.MirrorID = b.MirrorID 
--------------------------------------------------
 
-- Insert from Ext_Dim_Mirror_Real ---------------
 

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.MirrorID ORDER BY 1) = 1
)   ON a.MirrorID = a_tgt.MirrorID
WHEN MATCHED THEN DELETE ;
MERGE INTO dwh_daily_process.migration_tables.Dim_Mirror AS a
USING dwh_daily_process.migration_tables.Ext_Dim_Mirror_Real AS b
ON a.MirrorID = b.MirrorID And a.CloseDateID = b.CloseDateID And a.CloseDateID = 0  
WHEN MATCHED 
THEN UPDATE SET 
Amount = b.Amount,
OpenOccurred = b.OpenOccurred,
OpenDateID = b.OpenDateID,
CloseOccurred = b.CloseOccurred,
CloseDateID = b.CloseDateID,
MirrorTypeID = b.MirrorTypeID,
CloseMirrorActionType = b.CloseMirrorActionType,
IsActive = CAST(b.IsActive AS INT),
IsOpenOpen = b.IsOpenOpen,
PauseCopy = b.PauseCopy,
MirrorSL = b.MirrorSL,
MirrorSLPercentage = b.MirrorSLPercentage,
RealizedEquity = b.RealizedEquity,
InitialInvestment = b.InitialInvestment,
WithdrawalSummary = b.WithdrawalSummary,
DepositSummary = b.DepositSummary,
RealziedPnL = b.RealziedPnL,
IsCopyFundMirror = b.IsCopyFundMirror,
UpdateDate = current_timestamp()
WHEN NOT MATCHED THEN INSERT 
(`MirrorID`
,`CID`
,`ParentCID`
,`ParentUserName`
,`Amount`
,`OpenOccurred`
,`OpenDateID`
,`CloseOccurred`
,`CloseDateID`
,`MirrorTypeID`
,`CloseMirrorActionType`
,`IsActive`
,`IsOpenOpen`
,`PauseCopy`
,`MirrorSL`
,`MirrorSLPercentage`
,`RealizedEquity`
,`InitialInvestment`
,`WithdrawalSummary`
,`DepositSummary`
,`RealziedPnL`
,`GuruTPV`
,`UseCopyDividend`
,IsCopyFundMirror
,UpdateDate)
VALUES(
b.`MirrorID`
,b.`CID`
,b.`ParentCID`
,b.`ParentUserName`
,b.`Amount`
,b.`OpenOccurred`
,b.`OpenDateID`
,b.`CloseOccurred`
,b.`CloseDateID`
,b.`MirrorTypeID`
,b.`CloseMirrorActionType`
,b.`CAST(IsActive AS INT)`
,b.`IsOpenOpen`
,b.`PauseCopy`
,b.`MirrorSL`
,b.`MirrorSLPercentage`
,b.`RealizedEquity`
,b.`InitialInvestment`
,b.`WithdrawalSummary`
,b.`DepositSummary`
,b.`RealziedPnL`
,b.`GuruTPV`
,b.`UseCopyDividend`
,b.IsCopyFundMirror
,current_timestamp()
);
--------------------------------------------------
-- Extract Ext_Dim_Mirror_SessionID --------------

TRUNCATE table dwh_daily_process.migration_tables.Ext_Dim_Mirror_SessionID

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Mirror_SessionID

	SELECT MirrorID
      , SessionID
	from dwh_daily_process.daily_snapshot.etoro_History_Mirror 
	Where
	MirrorOperationID = 1 and 
		((
		ModificationDate >= V_Yesterday
		and 
	                   ModificationDate < V_CurrentDate
		)
	
	or
		(
		Occurred >= V_Yesterday
		and
		Occurred < V_CurrentDate
		and
	                  ModificationDate >= V_Yesterday
		));
--------------------------------------------------
--  Update from Ext_Dim_Mirror_SessionID ---------
	-- [stub] MERGE INTO ... USING (broken `_tgt` references) elided -- Synapse stats/PK rebuild has no UC equivalent

END;
