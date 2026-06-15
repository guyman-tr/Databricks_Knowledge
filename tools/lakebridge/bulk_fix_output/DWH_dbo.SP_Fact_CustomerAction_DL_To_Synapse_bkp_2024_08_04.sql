USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04(
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
DECLARE V_DateID INT 
;
-- =============================================
-- Author:      <Re'em Cohen>
-- Create Date: 2021-08-01
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Fact_CustomerAction_DL_To_Synapse] '2024-01-23'
-- =============================================
/**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2022-02-03		Inbal BML	   Add SettlementTypeID 
 2024-01-07	    Inbal BML	   change [DWH_staging].[etoro_Trade_Position] to [DWH_staging].[etoro_Trade_OpenPositionEndOfDay] and [DWH_staging].[etoro_History_Position] to [DWH_staging].[etoro_History_ClosePositionEndOfDay]
 2024-05-01     Boris P  Partiton [STS_Audit_UserOperationsData]
*********************************************************************************************/
   -- exec [SP_Fact_CustomerAction] '2019-03-18'
  --DECLARE @dt as DATE = cAST(GETDATE()-1 AS DATE)
  --'2021-07-01'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Check Exist Partition Fact_CustomerAction -----------------------

call dwh_daily_process.migration_tables.SP_Fact_CustomerAction_CheckExistPartition(V_Yesterday);
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Customer
 
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Customer 
	(		
	  `CID` 
	 ,`GCID`
	 ,`UserName`  
	 ,`UserNameCalc`
	)
	SELECT
	   `CID`
	  ,`GCID`
	  ,`UserName`
	,Lower(UserName) as UserNameCalc
	FROM dwh_daily_process.daily_snapshot.etoro_Customer_CustomerStatic;
--------------------------------------------------------------------
-- Ext_FCA_Real_Audit_Loggin ---------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_Audit_Loggin

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Audit_Loggin
	(`LoginID`
           ,`CID`
           ,`LoggedIn`
           ,`LoggedOut`
           ,`ClientVersion`
           ,`IP`
           ,`SessionID`
           ,`PlatformID`)
	SELECT 
	LoginID, 
	CID, 
	LoggedIn,
	0 AS LoggedOut, 
	ClientVersion, 
	IP,
	SessionIdentifier as SessionID ,--Browser,ApplicationIdentifierAgg,
	CASE
	---- Wallet
	WHEN Browser = 'Android' and GatewayAppId =2  then 118
	WHEN Browser = 'iOS' and GatewayAppId =2  then 119
	WHEN Browser = 'Browsers' and GatewayAppId =2 then 120
	---- EtoroX
	WHEN Browser = 'Android' and GatewayAppId =4  then 121
	WHEN Browser = 'iOS' and GatewayAppId =4  then 122
	WHEN Browser = 'Browsers' and GatewayAppId =4 then 123
	---- Delta 
	WHEN Browser = 'Android' and GatewayAppId =8  then 124
	WHEN Browser = 'iOS' and GatewayAppId =8  then 125
	WHEN Browser = 'Browsers' and GatewayAppId =8 then 126
	---- Etoro
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'openbook' then 101
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'other' then 102
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'registrationapi' then 103
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'retoro' then 104
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'retoroandroid' then 105
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'trader' then 106
	WHEN Browser = 'Android' and ApplicationIdentifierAgg = 'walletandroid' then 118

	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'openbook' then 107
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'other' then 108
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'registrationapi' then 109 
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'retoro' then 110
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'retoroios' then 111
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'trader' then 112
	WHEN Browser = 'iOS' and ApplicationIdentifierAgg = 'walletios' then 119

	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'trader' then 113
	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'openbook' then 114
	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'other' then 115
	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'registrationapi' then 116 
	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'retoro' then 117
	WHEN Browser = 'Browsers' and ApplicationIdentifierAgg = 'walletweb' then 120
	else 99 end as PlatformID
	from
	(
	select cast(a.LoggedIn as TIMESTAMP) as LoggedIn,
	---case when Browser = 'Browsers' then 'Web' else 'Mobile' end as "Web/Mobile",
	Browser,
	CASE
	--when ApplicationIdentifier in ('retoro','ReToro') then 'retoro'
	when ApplicationIdentifier = 'retoro, retoro' then 'retoro'
	--when ApplicationIdentifier in ('retoroios','ReToroIOS') then 'retoroios'
	--when ApplicationIdentifier in ('retoroandroid','ReToroAndroid') then 'retoroandroid'

	when lower(ApplicationIdentifier) in ('retoro') then 'retoro'
	when lower(ApplicationIdentifier) in ('retoroios') then 'retoroios'
	when lower(ApplicationIdentifier) in ('retoroandroid') then 'retoroandroid'

	when ApplicationIdentifier = 'androidretoro' then 'retoroandroid'
	when ApplicationIdentifier = 'androidetoro' then 'retoroandroid'
	when ApplicationIdentifier in ('registrationapi','registrationservice') then 'registrationapi'

	when ApplicationIdentifier = 'walletweb' then 'retoro'
	when ApplicationIdentifier = 'walletios' then 'retoroios'
	when ApplicationIdentifier = 'walletandroid' then 'retoroandroid'

	when ApplicationIdentifier = 'iostrader' then 'trader'
	when ApplicationIdentifier = 'androidtrader' then 'trader'
	when ApplicationIdentifier = 'webtrader' then 'trader'

	when ApplicationIdentifier = 'iosopenbook' then 'openbook'
	when ApplicationIdentifier = 'androidopenbook' then 'openbook'
	when ApplicationIdentifier = 'openbook' then 'openbook'
	when ApplicationIdentifier = 'openbook_news_publisher' then 'openbook'
	else 'other' END AS ApplicationIdentifierAgg
	,LoginID
	,CID
	,LoggedOut
	,ClientVersion
	,`IP`
	,SessionIdentifier
	,GatewayAppId
	from
	(
	SELECT ApplicationIdentifier as ApplicationIdentifier
	,0 as LoginID
	,EnvironmentDetailsFirst
	,ApplicationIdentifierFromFirst
	,RealCid as CID,
	CAST(CreatedAt as TIMESTAMP) as LoggedIn,
	CASE
	WHEN lower(EnvironmentDetailsFirst) LIKE '{`useragent`:null}' and ApplicationIdentifierFromFirst = 'retoroandroid' THEN 'Android'
	WHEN lower(EnvironmentDetailsFirst) LIKE '{`useragent`:null}' and ApplicationIdentifierFromFirst = 'retoroios' THEN 'iOS'
	WHEN lower(EnvironmentDetailsFirst) LIKE '%android%' THEN 'Android'
	WHEN lower(EnvironmentDetailsFirst) LIKE '%iphone%' or lower(EnvironmentDetailsFirst) LIKE '%ipad%' THEN 'iOS'
	WHEN ApplicationIdentifier LIKE '%android%' THEN 'Android'
	WHEN ApplicationIdentifier LIKE '%retoroios%' THEN 'iOS'

	WHEN ApplicationIdentifier LIKE '%iostrader%' THEN 'iOS'
	WHEN ApplicationIdentifier LIKE '%androidtrader%' THEN 'Android'

	WHEN ApplicationIdentifier LIKE '%iosopenbook%' THEN 'iOS'
	WHEN ApplicationIdentifier LIKE '%androidopenbook%' THEN 'Android'

	WHEN ApplicationIdentifier LIKE '%walletios%' THEN 'iOS'
	WHEN ApplicationIdentifier LIKE '%walletandroid%' THEN 'Android'

	ELSE 'Browsers'
	END as Browser,
	0 as LoggedOut,
	CASE ApplicationIdentifier
	 WHEN 'webtrader' THEN 2
	 WHEN 'iostrader' THEN 8
	 WHEN 'androidtrader' THEN 6
	 WHEN 'androidopenbook' THEN 5
	 WHEN 'iosopenbook' THEN 7
	 WHEN 'openbook' THEN 1
	 ELSE 99
	 END ClientVersion,
	CAST(`ClientIp` as STRING) as `IP`,
	SessionId AS SessionIdentifier,
	GatewayAppId
	from dwh_daily_process.daily_snapshot.STS_Audit_UserOperationsData LH 
	left join
	(
	Select CID, SessionIdentifier as SessionIdentifierFirst, EnvironmentDetails as EnvironmentDetailsFirst,ApplicationIdentifierFrom as ApplicationIdentifierFromFirst
	from
	(
	SELECT
	RealCid as CID,
	CAST(CreatedAt as TIMESTAMP) as LoggedIn,
	SessionId AS SessionIdentifier,
	UserAgent as EnvironmentDetails,ApplicationIdentifier AS  ApplicationIdentifierFrom ,
	ROW_NUMBER() OVER (PARTITION BY RealCid,SessionId  ORDER BY CreatedAt) rn
	from dwh_daily_process.daily_snapshot.STS_Audit_UserOperationsData 
	where CAST(CreatedAt as TIMESTAMP) >= DATEADD(day, DATEDIFF(7, V_Yesterday), 0) and  CAST(CreatedAt as TIMESTAMP) <= V_CurrentDate
	AND LoginTypeName = 'Login'
	) a
	WHERE rn = 1
	) LHS on LH.RealCid = LHS.CID and LH.SessionId = LHS.SessionIdentifierFirst
	where CAST(CreatedAt as TIMESTAMP) >= DATEADD(day, DATEDIFF(7, V_Yesterday), 0) and  CAST(CreatedAt as TIMESTAMP) <= V_CurrentDate
	AND LHS.SessionIdentifierFirst is not NULL
	AND LoginTypeName = 'Login'
	) a
	) b
	WHERE CAST(LoggedIn as TIMESTAMP) >= V_Yesterday 
	AND CAST(LoggedIn as TIMESTAMP) < V_CurrentDate
	and  `CID`  <>0;
--------------------------------------------------------------------


--DELETE FROM dwh_daily_process.migration_tables.STS_User_Operations_Data_History
--WHERE [DateID] =  convert(int,convert(varchar,dateadd(day,datediff(day,0,@Yesterday),0),112)) 
call dwh_daily_process.migration_tables.SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE(V_dt);
INSERT INTO dwh_daily_process.migration_tables.STS_User_Operations_Data_History_SWITCH_SINGLE 
(
    `Gcid` ,
    `RealCid` ,
    `DemoCid` ,
    `ApplicationIdentifier` ,
    `ApplicationVersion` ,
    `ClientIp` ,
    `ClientName` ,
    `CreatedAt` ,
    `UserAgent` ,
    `AccessTokenHashed` ,
   `ClientDeviceId` ,
    `ParentSessionId` ,
    `AccountTypeName` ,
    `LoginTypeName` ,
    `SessionId` ,
    `GatewayAppId` ,
	`ProxyType` ,
	`CountryISOCode`,
	`AdditionalData`,
	`DateID`,
	`UpdateDate`
	)
SELECT 
    `Gcid` ,
    `RealCid` ,
    `DemoCid` ,
    `ApplicationIdentifier` ,
    `ApplicationVersion` ,
    `ClientIp` ,
    `ClientName` ,
    `CreatedAt` ,
    `UserAgent` ,
    `AccessTokenHashed` ,
    `ClientDeviceId`,
    `ParentSessionId` ,
    `AccountTypeName` ,
    `LoginTypeName` ,
    `SessionId` ,
    `GatewayAppId` ,
	`ProxyType` ,
	`CountryISOCode`,
	`AdditionalData`,
    CAST(date_format(DATEADD(day, DATEDIFF(0, V_Yesterday), 0), 'yyyyMMdd') AS int)  ,
    current_timestamp()
FROM dwh_daily_process.daily_snapshot.STS_Audit_UserOperationsData  
WHERE `CreatedAt` >= V_Yesterday AND `CreatedAt` < V_CurrentDate


;
call dwh_daily_process.migration_tables.SP_STS_User_Operations_Data_History_SWITCH();
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_Loggin

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_Loggin
	SELECT
	LoginID,
	CID,
	LoggedIn,
	LoggedOut,
	IP
	FROM
	dwh_daily_process.daily_snapshot.etoro_Billing_Login 
	WHERE LoggedIn >= V_Yesterday AND  LoggedIn <  V_CurrentDate;

		

--------------------------------------------------------------------
-- Ext_FCA_Real_Customer_Registration ------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_Customer_Registration

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Customer_Registration
	(
	 `CID`
	 ,`Registered`
	 ,`IsReal` 
	 ,`ActionTypeID` 
	 ,`PlatformTypeID`
	 ,`DateID` 
	 ,`TimeID` 
	 ,`FunnelID`  
	 ,`IP` 
	 ,`CountryIDByIP` 
	 ,`PlatformID`
	)
	SELECT DISTINCT 
	`CID`,
	`Registered`,
	cast(`IsReal` as tinyint) as `IsReal`,
	41 as `ActionTypeID`,
	99 as `PlatformTypeID`,
	CAST(date_format(`Registered`, 'yyyyMMdd') AS INT) as `DateID`,
	EXTRACT(HOUR from `Registered`) as `TimeID`,FunnelID
	,`IP`
	,`CountryIDByIP`
	,NULL as NULL_column
	FROM dwh_daily_process.daily_snapshot.etoro_Customer_CustomerStatic 
	WHERE Registered>= V_Yesterday AND Registered< V_CurrentDate;

--------------------------------------------------------------------
-- Ext_FCA_Real_Trade_Position -------------------------------------

--SSIS flow use derived columns. one column adds as a new columns and
-- assigned with Null as default value. second column is CAST(IsSettled AS INT), intended
-- to replace the origin by casting it to four-byte signed integer.
	
-- Here using INSERT INTO command, any column that is not specified assigned with her
--default value. the second problem solved by staging table that contain
--the relevant field.
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position
	(	
	   `PositionID`
      ,`CID`
      ,`CurrencyID`
      ,`ProviderID`
      ,`InstrumentID`
      ,`HedgeID`
      ,`HedgeServerID`
      ,`Leverage`
      ,`Amount`
      ,`AmountInUnitsDecimal`
      ,`UnitMargin`
      ,`InitForexRate`
      ,`NetProfit`
      ,`SpreadedPipBid`
      ,`SpreadedPipAsk`
      ,`IsBuy`
      ,`CloseOnEndOfWeek`
      ,`EndOfWeekFee`
      ,`Commission`
      ,`CommissionOnClose`
      ,`OpenOccurred`
      ,`CloseOccurred`
      ,`ParentPositionID`
      ,`OrigParentPositionID`
      ,`MirrorID`
      ,`IsOpenOpen`
      ,`FullCommission`
      ,`FullCommissionOnClose`
      ,`RedeemStatus`
      ,`RedeemID`
      ,`ReopenForPositionID`
      ,`IsReOpen`
      ,`CommissionOnCloseOrig`
      ,`FullCommissionOnCloseOrig`
      ,`InitialUnits`
      ,`IsSettled`
      ,`IsDiscounted`
      ,`CommissionByUnits`
      ,`FullCommissionByUnits`
	  ,`SettlementTypeID`
	)

	SELECT
	PositionID,
	CID,
	CurrencyID,
	ProviderID,
	a.InstrumentID,
	HedgeID,
	HedgeServerID,
	Leverage,
	COALESCE(Amount, 0)  AS Amount,
	AmountInUnitsDecimal,
	UnitMargin,
	InitForexRate,
	0 AS NetProfit, 
	SpreadedPipBid,
	SpreadedPipAsk,
	IsBuy,
	COALESCE(CAST(CloseOnEndOfWeek AS BOOLEAN), FALSE) as CloseOnEndOfWeek,
	EndOfWeekFee,
	Commission,
	0 AS CommissionOnClose,
	Occurred AS OpenOccurred,
	CAST(0 AS TIMESTAMP) AS CloseOccurred,
	ParentPositionID,
	OrigParentPositionID,
	MirrorID,
	IsOpenOpen,
	COALESCE(`FullCommission`, 0.00) AS FullCommission,
	0.00 AS FullCommissionOnClose,
	RedeemStatus,
	NULL as RedeemID,
	ReopenForPositionID,
	CASE WHEN ReopenForPositionID is not null THEN 1 END AS IsReOpen,
	0.00 AS CommissionOnCloseOrig,
	0.00 AS FullCommissionOnCloseOrig
	, InitialUnits
	,CASE 
	WHEN CAST(IsSettled AS INT) in (1,0) THEN cast(IsSettled as int)  
	WHEN IsBuy = 1 And Leverage = 1 AND b.InstrumentTypeID IN (10,5,6) THEN 1 
	ELSE 0 
	END AS IsSettled
	,CAST(IsDiscounted AS INT)
	,`CommissionByUnits`
	,`FullCommissionByUnits`
	,SettlementTypeID
	FROM
	dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay a 
	left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
	on a.InstrumentID = b.InstrumentID
	WHERE Occurred>= DATEADD(HOUR, -1, V_Yesterday)  and Occurred< DATEADD(DAY, DATEDIFF(-1, V_CurrentDate), 0);

	
--------------------------------------------------------------------
-- Ext_FCA_Real_Position -------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_History_Position

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_History_Position
	(`PositionID`, 
	`CID`, 
	`CurrencyID`, 
	`ProviderID`, 
	`InstrumentID`, 
	`HedgeID`, 
	`HedgeServerID`, 
	`Leverage`,
	`Amount`, 
	`AmountInUnitsDecimal`, 
	`UnitMargin`, 
	`InitForexRate`, 
	`NetProfit`, 
	`SpreadedPipBid`, 
	`SpreadedPipAsk`, 
	`IsBuy`, 
	`CloseOnEndOfWeek`, 
	`EndOfWeekFee`, 
	`Commission`, 
	`CommissionOnClose`, 
	`OpenOccurred`, 
	`CloseOccurred`, 
	`ParentPositionID`, 
	`OrigParentPositionID`,
	`MirrorID`, 
	`IsOpenOpen`, 
	`FullCommission`,
	`FullCommissionOnClose`, 
	`RedeemStatus`, 
	`RedeemID`, 
	`ReopenForPositionID`, 
	`IsReOpen`, 
	`CommissionOnCloseOrig`, 
	`FullCommissionOnCloseOrig`, 
	`OriginalPositionID`,
	`IsSettled`, 
	`InitialUnits`, 
	`IsDiscounted`, 
	`CommissionByUnits`, 
	`FullCommissionByUnits`,
	`SettlementTypeID`)

		SELECT 
		PositionID,
		CID,
		CurrencyID,
		ProviderID,
		a.InstrumentID,
		HedgeID,
		HedgeServerID,
		Leverage,
		COALESCE(Amount, 0) as Amount,
		AmountInUnitsDecimal,
		UnitMargin,
		InitForexRate,
		NetProfit,
		SpreadedPipBid,
		SpreadedPipAsk,
		IsBuy,
		CloseOnEndOfWeek,
		EndOfWeekFee,
		Commission,
		CommissionOnClose,
		OpenOccurred,
		CloseOccurred,
		COALESCE(`ParentPositionID`, 0) AS ParentPositionID,
		OrigParentPositionID,
		MirrorID,
		IsOpenOpen,
		COALESCE(`FullCommission`, 0.00) AS FullCommission,
		COALESCE(`FullCommissionOnClose`, 0.00) AS FullCommissionOnClose
		                   ,RedeemStatus
		                   , RedeemID
		,ReopenForPositionID
		,CASE WHEN ReopenForPositionID IS NOT NULL THEN 1 END AS IsReOpen
		,CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose END AS CommissionOnCloseOrig
		,CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose END AS FullCommissionOnCloseOrig
		,OriginalPositionID
	
		,CASE WHEN CAST(IsSettled AS INT) in (1,0) THEN cast(IsSettled as int)  WHEN IsBuy = 1 And Leverage = 1 and b.InstrumentTypeID in (10,5,6) THEN 1 else 0  END AS IsSettled
		,InitialUnits
		,CAST(IsDiscounted AS INT)
		,`CommissionByUnits`
		,`FullCommissionByUnits`
		,SettlementTypeID
		FROM
		dwh_daily_process.daily_snapshot.etoro_History_ClosePositionEndOfDay a  
		left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
		ON a.InstrumentID = b.InstrumentID
		WHERE 
		(OpenOccurred>=DATEADD(HOUR, -1, V_Yesterday)  and OpenOccurred< DATEADD(DAY, DATEDIFF(-1, V_Yesterday), 0))
		OR (CloseOccurred>= V_Yesterday  and CloseOccurred< DATEADD(DAY, DATEDIFF(-1, V_Yesterday), 0));  --OPTION	(RECOMPILE)
--------------------------------------------------------------------
-- Ext_FCA_Real_History_Credit_ForFactAction -----------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction


;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction
	(`CID`, `Occurred`, `Credit`, `Payment`, `TotalCashChange`, `CreditTypeID`, `CashoutID`, `CampaignID`, `PositionID`, 
	`DepositID`, `WithdrawID`, `PaymentID`, `BonusTypeID`, `MirrorID`, `CompensationReasonID`, `WithdrawPaymentID`, 
	`BonusCredit`, `CreditID`, `Description`, `MoveMoneyReasonID`)

--[MirrorDividendID]--[MoveMoneyReasonID]
	SELECT 
	  CID,
		Occurred,
		Credit,
		Payment,
		TotalCashChange,
		CreditTypeID,
		CashoutID,
		CampaignID,
		PositionID,
		DepositID,
		WithdrawID,
		PaymentID,
		BonusTypeID,
		MirrorID,
		CompensationReasonID,
		WithdrawProcessingID,
		BonusCredit,
		CreditID
		,Description
		,`MoveMoneyReasonID`
	FROM dwh_daily_process.daily_snapshot.etoro_History_Credit 
	WHERE WithdrawProcessingID IS NULL AND (Occurred>= V_Yesterday and Occurred< V_CurrentDate)
	UNION 
	SELECT CID,
		MIN(Occurred) as Occurred,
		Credit,
		Payment,
		TotalCashChange,
		CreditTypeID,
		CashoutID,
		CampaignID,
		PositionID,
		DepositID,
		WithdrawID,
		PaymentID,
		BonusTypeID,
		MirrorID,
		CompensationReasonID,
		WithdrawProcessingID,
		BonusCredit,
		MIN(CreditID) as CreditID
		,Description
		,`MoveMoneyReasonID`
	FROM dwh_daily_process.daily_snapshot.etoro_History_Credit 
	WHERE WithdrawProcessingID IS NOT NULL AND(Occurred>= V_Yesterday and Occurred < V_CurrentDate)
	GROUP BY CID,
			Credit,
			Payment,
			TotalCashChange,
			CreditTypeID,
			CashoutID,
			CampaignID,
			PositionID,
			DepositID,
			WithdrawID,
			PaymentID,
			BonusTypeID,
			MirrorID,
			CompensationReasonID,
			WithdrawProcessingID,
			BonusCredit
			,Description
			,`MoveMoneyReasonID`;



--------------------------------------------------------------------
-- Ext_FCA_BackOffice_Customer -------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_BackOffice_Customer
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_BackOffice_Customer
	SELECT 
	b.CID,
	b.VerificationLevelID,
	b.RiskStatusID,
	b.RiskClassificationID,
	--b.isEmployeeAccount,
	0 AS isEmployeeAccount,
	b.GuruStatusID,
	b.AccountTypeID,
	b.RegulationID,
	b.ManagerID,
	b.`ValidFrom` AS  Occurred
	FROM dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer b 
	WHERE 
	b.`ValidFrom`>= V_Yesterday
	AND b.`ValidFrom`< V_CurrentDate;
	
--------------------------------------------------------------------
-- Ext_FCA_PositionsProcessedForIndexDividnds ----------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_PositionsProcessedForIndexDividnds
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_PositionsProcessedForIndexDividnds
	(
	  `PositionID` 
	 ,`DividendID` 
	 ,`ProcessTime`
	 ,`DividendValueInCurrency`
	)
	SELECT a.PositionID,	a.DividendID,	a.ProcessTime, b.DividendValueInCurrency
	FROM dwh_daily_process.daily_snapshot.etoro_Trade_PositionsProcessedForIndexDividnds a
	join dwh_daily_process.daily_snapshot.etoro_Trade_IndexDividends b 
	ON a.DividendID=b.DividendID
	WHERE a.ProcessTime>= V_Yesterday AND a.ProcessTime< V_CurrentDate;
--------------------------------------------------------------------
-- Ext_FCA_Tran_Billing_Withdraw -----------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Tran_Billing_Withdraw
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Tran_Billing_Withdraw
	(`WithdrawID`,
	`CID`, 
	`CashoutStatusID`, 
	`Amount`, 
	`IPAddress`,
`ModificationDate`, 
	`FundingTypeID`, 
	`Fee`)
	SELECT 	
	   `WithdrawID`
      ,`CID`
      ,`CashoutStatusID`
      ,`Amount`
     ,CAST(cast(`IPAddress` as decimal(18,0) )as STRING) `IPAddress`
      ,`ModificationDate`
      ,`FundingTypeID`
      ,`Fee`
	FROM dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw;


--------------------------------------------------------------------
-- Ext_FCA_Billing_Withdraw ----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Billing_Withdraw
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Billing_Withdraw
	(
	 `WithdrawID` 
	 ,`CID` 
	 ,`Amount` 
	 ,`IPAddress` 
	 ,`ModificationDate` 
	 ,`Fee` 
	 ,`FundingTypeID`
	)
	SELECT
	 COALESCE(a.WithdrawID, 0) as WithdrawID
	 ,  CID
	 , COALESCE(Amount, 0) as Amount
	 , CAST(cast(`IPAddress` as decimal(18,0) )as STRING) `IPAddress`
	 , ModificationDate
	 ,Fee /*We Bring the CO fee only on Requset and processed CO in order to be able to calculate Unrealized fee*/
	, FundingTypeID
	FROM
	(
		SELECT Distinct `WithdrawID`
		FROM dwh_daily_process.daily_snapshot.etoro_History_WithdrawAction 
		WHERE
			ModificationDate >= V_Yesterday
			AND
			ModificationDate < V_CurrentDate
			AND 
			CashoutStatusID=3 
			AND WithdrawID NOT IN
			(
				SELECT WithdrawID AS WithdrawID_ModificationDateMin
				From
				(
					SELECT WithdrawID, min(ModificationDate) AS ModificationDateMin
					FROM
						dwh_daily_process.daily_snapshot.etoro_History_WithdrawAction 
					WHERE
						ModificationDate < V_Yesterday
						and
						CashoutStatusID=3
					group by WithdrawID
				) a
			)
	)  a
	join  
	dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw b  
	on
	a.WithdrawID=b.WithdrawID; -- OPTION	(RECOMPILE)


--------------------------------------------------------------------
-- Ext_FCA_Real_Cashier_CashoutToFunding ---------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_CashoutToFunding
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_CashoutToFunding
	(
	  `WithdrawID`
	 ,`CID`
	 , `CashoutStatusID`
	 , `Amount`
     , `IPAddress`
	 , `ModificationDate`
	 , `FundingTypeID`
	 , `WithdrawPaymentID`
	 , `SessionID`
	 )
	SELECT 
		a.WithdrawID,
		CID,
		CashoutStatusID,
		Amount,
		CAST(cast(`IPAddress` as decimal(18,0) )as STRING)IPAddress,
		ModificationDate,
		b.FundingTypeID,
		ID as `WithdrawPaymentID`,
		SessionID
		FROM dwh_daily_process.daily_snapshot.etoro_Billing_vWithdrawToFunding a 
		JOIN (
		SELECT 
		CID,
		WithdrawID,
		IPAddress,
		FundingTypeID,
		SessionID
	FROM dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw 
	) b
	ON a.WithdrawID = b.WithdrawID;
--------------------------------------------------------------------
-- Ext_FCA_Deposit_Attempt -----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Deposit_Attempt
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Deposit_Attempt
	(
	  `CID` 
	 ,`PaymentStatusID` 
	 ,`Amount` 
	 ,`ModificationDate`
	)
	SELECT
		 CID
		,PaymentStatusID
		,Amount
		,ModificationDate
	FROM dwh_daily_process.daily_snapshot.etoro_Billing_vDeposit
	WHERE PaymentStatusID<>2 
	AND
	ModificationDate >= V_Yesterday
	AND
	ModificationDate < V_CurrentDate;

--------------------------------------------------------------------
-- Remove Duplicate Positions --------------------------------------
  
MERGE INTO  dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position A_TGT USING (
select *   
FROM  _tgt,
   `DWH_dbo`_tgt.Ext_FCA_Real_Trade_Position  
INNER JOIN  `DWH_dbo`_tgt.Ext_FCA_History_Position  ON  Ext_FCA_Real_Trade_Position_tgt.PositionID = Ext_FCA_History_Position_tgt.PositionID 
--------------------------------------------------------------------
 
-- Ext_FCA_Position_AirDrop ----------------------------------------
 
)   ON  COALESCE(.Ext_FCA_Real_Trade_Position,'_NULL_') = COALESCE(.Ext_FCA_Real_Trade_Position,'_NULL_') 
AND  COALESCE(.Ext_FCA_History_Position,'_NULL_') = COALESCE(.Ext_FCA_History_Position,'_NULL_') 
AND  COALESCE(.PositionID,'_NULL_') = COALESCE(.PositionID,'_NULL_') 
WHEN MATCHED THEN DELETE ;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Position_AirDrop
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Position_AirDrop
	(
	 `PositionID`
	)
	SELECT PositionID FROM dwh_daily_process.daily_snapshot.etoro_Trade_PositionAirdropLog
	WHERE PositionID IS NOT NULL 
	AND ExecutionOccurred >= V_Yesterday AND ExecutionOccurred < V_CurrentDate;
--------------------------------------------------------------------
-- Ext_FCA_CountryIP -----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_CountryIP
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_CountryIP
	(
	  `CountryID` 
	 ,`IPFrom` 
	 ,`IPTo` 
	 ,`RegionID`
	 ,`UpdateDate`
	)
	SELECT * , current_timestamp() as UpdateDate
	FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CountryIP
;
WITH FULLSCAN;
--------------------------------------------------------------------
-- Ext_FCA_PositionChangeLog ---------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_PositionChangeLog
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_PositionChangeLog
	(
	  `PositionID` 
	 ,`CID` 
	 ,`Occurred` 
	 ,`IsSettled`
	 ,`PreviousIsSettled`
	)
	SELECT 
	PositionID,
	CID,
	Occurred,
	CAST(IsSettled AS INT) IsSettled,
	CAST(PreviousIsSettled AS INT) PreviousIsSettled
	FROM
	(
		SELECT
		pl.PositionID
		,pl.CID
		,Occurred
		,CAST(pl.IsSettled AS INT)
		,CAST(pl.PreviousIsSettled AS INT)
		, ROW_NUMBER() OVER (PARTITION BY pl.PositionID ORDER BY pl.Occurred ) rn
		FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog pl 
		WHERE Occurred > V_Yesterday
		---and isnull(CAST(pl.IsSettled AS INT),-1) <> isnull(CAST(pl.PreviousIsSettled AS INT),-1)
		and CAST(pl.IsSettled AS INT) <> CAST(pl.PreviousIsSettled AS INT)
	) a
	WHERE rn =1;
--------------------------------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_OpenBook_Engagement

;
INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_OpenBook_Engagement
           (`EngagementType`
           ,`Occurred`
           ,`UserName`
           ,`PostRootID`
           ,`ApplicationName`
           ,`UserNameCalc`)
SELECT TypeName
     , OccurredAt
     , Username
     , RootId
     , ApplicationName 
     , Lower(Right(Username,LENGTH(Username)-1)) as UserNameCalc
From dwh_daily_process.daily_snapshot.Streams0_dbo_Entries 
Where TypeName In ('Like', 'Comment', 'Discussion')
And OccurredAt >= V_Yesterday
And OccurredAt < V_CurrentDate;


-- Ext_FCA_Billing_Deposit -----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Billing_Deposit
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Billing_Deposit
	(
	 `DepositID` 
	,`ModificationDate` 
	,`IPAddress` 
	,`FundingTypeID` 
	,`SessionID` 
	,`IsFTD`
	,`PaymentStatusID`
	)
	SELECT
		DepositID
		,ModificationDate
		,CAST(cast(`IPAddress` as decimal(18,0) )as STRING)IPAddress
		, FundingTypeID
		,COALESCE(SessionID, 0) AS SessionID
		, CASE 
			WHEN CAST(IsFTD AS INT) IN (1,0) then cast(IsFTD AS INT)  
		  END AS IsFTD
		,PaymentStatusID
		
	FROM  dwh_daily_process.daily_snapshot.etoro_Billing_Deposit bd
			JOIN dwh_daily_process.daily_snapshot.etoro_Billing_Funding bf
			ON bd.FundingID = bf.FundingID
	WHERE 		
	bd.ModificationDate >= V_Yesterday
	AND
	bd.ModificationDate < V_CurrentDate
	AND bd.PaymentStatusID in ( 2,11);
--------------------------------------------------------------------
-- Ext_FCA_Mirror_Session ------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Mirror_Session
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Mirror_Session
	(
	  MirrorID
	  ,SessionID
	  ,Occurred
	)
	SELECT  MirrorID, SessionID, Occurred
	FROM dwh_daily_process.daily_snapshot.etoro_History_Mirror
	WHERE
	Occurred >= V_Yesterday
	AND
	Occurred < V_CurrentDate
	AND MirrorOperationID = 1; -- = register mirror
--------------------------------------------------------------------
-- Ext_FCA_Position_Session ----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Position_Session
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Position_Session
	(
	  PositionID
	 ,SessionID
	 ,Occurred
	)
	SELECT PositionID, SessionID,Occurred
	FROM
	(
		SELECT PositionID, COALESCE(SessionID, -1) as SessionID,Occurred,max(PositionChangeID) as MaxPositionChangeID
		--SELECT PositionID, SessionID,Occurred,max(PositionChangeID) as MaxPositionChangeID
		--FROM [DWH_staging].[etoro_History_PositionChangeLog_Active]
		FROM dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog
		Where ChangeTypeID = 0
		AND Occurred >= V_Yesterday
		AND
		Occurred < V_CurrentDate
		GROUP BY PositionID, SessionID,Occurred
	) a;
--------------------------------------------------------------------
-- Ext_FCA_ActionTypeID_14 -----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_ActionTypeID_14
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_ActionTypeID_14
	(
	  SessionID
	 ,`PlatformID`
	 ,DateID
	)
	SELECT SessionID, `PlatformID`,DateID
	FROM dwh_daily_process.migration_tables.Fact_CustomerAction
	WHERE ActionTypeID = 14;
	--and [DateID] between  cast(dateadd(day,datediff(day,-30,@Yesterday),0) as int)
	--and cast(@Yesterday as int)
--------------------------------------------------------------------
-- SP_Fact_CustomerAction ------------------------------------------
call dwh_daily_process.migration_tables.SP_Fact_CustomerAction(V_Yesterday);
SET V_DateID =  date_format(V_dt, 'yyyyMMdd')

;
	DELETE FROM dwh_daily_process.migration_tables.Fact_CustomerAction WHERE DateID = V_DateID;
--------------------------------------------------------------------
-- Insert to Fact_CustomerAction_Create_SWITCH_SINGLE --------------
	--INSERT INTO [DWH_dbo].Fact_CustomerAction_SWITCH_SINGLE
	--INSERT INTO [DWH_dbo].Fact_CustomerAction
	INSERT INTO dwh_daily_process.migration_tables.Fact_CustomerAction
	(
	  `HistoryID`
	 ,`GCID` 
	 ,`RealCID` 
	 ,`DemoCID` 
	 ,`Occurred`
	 ,`IPNumber`
	 ,`IsReal` 
	 ,`ActionTypeID`  
	 ,`PlatformTypeID`
	 ,`InstrumentID` 
	 ,`Amount` 
 	 ,`Leverage`  
	 ,`NetProfit` 
	 ,`Commission`
	 ,`PositionID`
	 ,`CampaignID`
	 ,`BonusTypeID`  
	 ,`FundingTypeID`
	 ,`LoginID` 
	 ,`MirrorID`
	 ,`WithdrawID` 
	 ,`DurationInSeconds` 
	 ,`PostID` 
	 ,`CaseID` 
	 ,`UpdateDate` 
	 ,`DateID`  
	 ,`TimeID`  
	 ,`StatusID`
	 ,`PreviousOccurred`    
	 ,`CompensationReasonID`
	 ,`WithdrawPaymentID`
	 ,`CommissionOnClose`
	 ,`IsPlug`   
	 ,`DepositID`
	 ,`PostRootID`
	 ,`FullCommission`
	 ,`FullCommissionOnClose` 
	 ,`RedeemID` 
	 ,`RedeemStatus`
	 ,`SessionID`
	 ,`IsRedeem` 
	 ,`RegulationIDOnOpen` 
	 ,`PlatformID` 
	 ,`ReopenForPositionID` 
	 ,`IsReOpen` 
	 ,`CommissionOnCloseOrig` 
	 ,`FullCommissionOnCloseOrig` 
	 ,`OriginalPositionID` 
	 ,`IsPartialCloseParent`
	 ,`IsPartialCloseChild` 
	 ,`InitialUnits`   
	 ,`PaymentStatusID`
	 ,`IsDiscounted` 
	 ,`IsSettled` 
	 ,`CommissionByUnits`    
	 ,`FullCommissionByUnits`
	 ,`IsFTD`		 
	 ,`CountryIDByIP`
	 ,`IsAnonymousIP`
	 ,`ProxyType` 
	 ,`IsFeeDividend` 
	 ,`IsAirDrop` 
	 ,`DividendID`
	 ,`MoveMoneyReasonID`
	 ,`SettlementTypeID`
	)
	SELECT 
	     HistoryID
		 ,GCID
		 , RealCID
		 , DemoCID
		 , Occurred
		 , COALESCE(IPNumber, 0) AS IPNumber
		 , IsReal
		 , ActionTypeID
		 , PlatformTypeID
		 , COALESCE(InstrumentID, 0) AS InstrumentID
		 , COALESCE(Amount, 0) AS Amount
		 , COALESCE(Leverage, 0) AS Leverage
		 , COALESCE(NetProfit, 0) AS NetProfit
		 , COALESCE(Commission, 0) AS Commission
		 , COALESCE(PositionID, 0) AS PositionID
		 , COALESCE(CampaignID, 0) AS CampaignID
		 , COALESCE(BonusTypeID, 0) AS BonusTypeID
		 , COALESCE(FundingTypeID, 0) AS FundingTypeID
		 , COALESCE(LoginID, 0) AS LoginID
		 , COALESCE(MirrorID, 0) AS MirrorID
		 , COALESCE(WithdrawID, 0) AS WithdrawID
		 , COALESCE(DurationInSeconds, 0) as DurationInSeconds
		 , NULL AS PostID
		 , COALESCE(CaseID, 0) as CaseID
		 , current_timestamp() as UpdateDate
		 , DateID
		 , TimeID
		 , StatusID
		 , PreviousOccurred
		 , COALESCE(CompensationReasonID, 0) AS CompensationReasonID
		 , COALESCE(WithdrawPaymentID, 0) as WithdrawPaymentID
		 , COALESCE(CommissionOnClose, 0) AS CommissionOnClose
		 , NULL AS IsPlug
		 , DepositID
		 , PostRootID
		 , FullCommission
		 , FullCommissionOnClose
		 , RedeemID
		 , RedeemStatus
		 , SessionID
		 , IsRedeem
		 , RegulationIDOnOpen
         , PlatformID
		,ReopenForPositionID
		,IsReOpen
		,CommissionOnCloseOrig
		,FullCommissionOnCloseOrig
		,OriginalPositionID
		, NULL AS IsPartialCloseParent
		,IsPartialCloseChild
		,InitialUnits
		,PaymentStatusID
		,CAST(IsDiscounted AS INT)
		,CAST(IsSettled AS INT)
		,CommissionByUnits
		,FullCommissionByUnits
		, CAST(IsFTD AS INT)
		, CountryIDByIP
		,IsAnonymousIP 
		,ProxyType
		,IsFeeDividend
		, IsAirDrop
		, DividendID
		,MoveMoneyReasonID
		,SettlementTypeID
		--,NULL AS NULL_1
		--,NULL AS NULL_2
		 		FROM
				dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
				WHERE 
				ActionTypeID is not null;
--------------------------------------------------------------------
-- SP_Fact_CustomerAction_SWITCH -----------------------------------
--	EXEC [DWH_dbo].SP_Fact_CustomerAction_SWITCH
--------------------------------------------------------------------
-- SP_Fact_CustomerAction_IsParitalCloseParent ---------------------
call dwh_daily_process.migration_tables.SP_Fact_CustomerAction_IsParitalCloseParent();
END;
