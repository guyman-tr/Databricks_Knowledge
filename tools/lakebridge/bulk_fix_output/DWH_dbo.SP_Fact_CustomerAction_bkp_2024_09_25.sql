USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerAction_bkp_2024_09_25(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_dateID INT ;

DECLARE V_dateID14daysAgo INT ;

DECLARE V_row_count int
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Fact_CustomerAction
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2018-05-09     Boris Slutski  drop table [DWH_dbo].Ext_FCA_Real_SocialAlert_Loggin - table not in use 
 2018-09-25     Boris Slutski  add  Redeem [DWH_dbo].Ext_Position tables
 2019-01-22     Boris Slutski  Add SesiioID & PlatformID for ActionTypeID in (2,41)
 2019-04-07     Boris Slutski  Add Update CAST(IsSettled AS INT) for OpenPosition
 2020-02-16     Boris Slutski  Add CountryIDByIP to ActionType = 41
 2020-11-30     Boris Slutski  Update script to ActionTypeID = 35 
 2021-11-29     Adi Ferber     Add MoveMoneyReasonID
 2022-02-03		Inbal BML	   Add SettlementTypeID 
 2022-04-03     Adi Ferber     Add Action type 42 - Cashout Rollback
 2022-05-10     Adi Ferber     Add new Action type 43-Reverse Deposit
 2023-09-27     Adi Ferber     Add IsFeeDividend=3 for sdrt
 2024-03-05		Inbal BML	   Add IsFeeDividend=4 for sdrt 
 2024-04-03     Nir H		   add ActionTypeID in(44,45) and MoveMoneyReason=5
 2024-06-02     Ofir A         add DLT columns
 2024-08-08     Ofir A         add Description to Fact_CustomerAction 

*********************************************************************************************/
 --   exec [DWH_dbo].[SP_Fact_CustomerAction] '2023-09-17'
    ---declare @dt datetime = cast(getdate()-1 as date)
	---declare @dt datetime = '2024-03-15'

SET V_dateID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;
SET V_dateID14daysAgo = CAST(date_format(DATEADD(DAY, -14, V_dt), 'yyyyMMdd') AS int);
--SELECT @dateID, @dateID14daysAgo
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All;
	insert into dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All
	(CID,
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
	WithdrawPaymentID,
	BonusCredit,
	CreditID,
	Description,
	MoveMoneyReasonID)
	------------------------2017-02-13 update to avoid duplicate WithdrawProcessingID
	----------pull unique WithdrawProcessingID separately-------
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
	WithdrawPaymentID,
	BonusCredit,
	CreditID,
	Description,
	MoveMoneyReasonID
	FROM dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction 
	WHERE WithdrawPaymentID IS NULL
	UNION ALL  
	SELECT 
	CID,
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
	WithdrawPaymentID,
	BonusCredit,
	MIN(CreditID) as CreditID
	,Description
	,MoveMoneyReasonID
	FROM dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction 
	WHERE WithdrawPaymentID IS NOT NULL
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
			WithdrawPaymentID,
			BonusCredit,
			Description,
			MoveMoneyReasonID
	
;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
TRUNCATE TABLE  dwh_daily_process.migration_tables.Ext_FCA_Real_Position;
INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Position 	
(PositionID,
									CID,
									Leverage,
									NetProfit,
									CommissionOnClose,
									Commission,
									InstrumentID,
									Amount,
									CurrencyID,
									ProviderID,
									HedgeID,
									HedgeServerID,
									AmountInUnitsDecimal,
									UnitMargin,
									InitForexRate,
									SpreadedPipBid,
									SpreadedPipAsk,
									IsBuy,
									CloseOnEndOfWeek,
									EndOfWeekFee,
									OpenOccurred,
									CloseOccurred,
									ParentPositionID,
									OrigParentPositionID,
									MirrorID,
									IsOpenOpen,
									FullCommission,
									FullCommissionOnClose,
								    RedeemStatus,
									RedeemID,
									ReopenForPositionID,
									IsReOpen,
									CommissionOnCloseOrig,
									FullCommissionOnCloseOrig,
									OriginalPositionID,
									IsSettled,
								    InitialUnits,
									IsDiscounted,
									CommissionByUnits,
									FullCommissionByUnits,
									SettlementTypeID,
									DLTOpen,
                                    DLTClose,
		                            OpenMarkupByUnits
									)
SELECT PositionID
	 , CID
	 , Leverage
	 , NetProfit
	 , CommissionOnClose
	 , Commission
	 , InstrumentID
	 , Amount
	 , CurrencyID
	 , ProviderID
	 , HedgeID
	 , HedgeServerID
	 , AmountInUnitsDecimal
	 , UnitMargin
	 , InitForexRate
	 , SpreadedPipBid
	 , SpreadedPipAsk
	 , IsBuy
	 , CloseOnEndOfWeek
	 , EndOfWeekFee
	 , OpenOccurred
	 , CloseOccurred
	 , ParentPositionID
	 , OrigParentPositionID
	 , MirrorID
	 , IsOpenOpen
     , FullCommission
	 , FullCommissionOnClose
	 , RedeemStatus
	 , RedeemID
	 , ReopenForPositionID
	 , IsReOpen
	 , CommissionOnCloseOrig
	 , FullCommissionOnCloseOrig
	 , OriginalPositionID
	 , CAST(IsSettled AS INT)
	 , InitialUnits
	 , CAST(IsDiscounted AS INT)
	 , CommissionByUnits
	 , FullCommissionByUnits
	 , SettlementTypeID
	 , DLTOpen
     , DLTClose
	 , OpenMarkupByUnits
	FROM dwh_daily_process.migration_tables.Ext_FCA_History_Position;




	/*START [DWH_dbo].Ext_FCA_Real_Position*/
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_PositionChangeLog b on a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Position	
(PositionID,
										CID,
										Leverage,
										NetProfit,
										CommissionOnClose,
										Commission,
										InstrumentID,
										Amount,
										CurrencyID,
										ProviderID,
										HedgeID,
										HedgeServerID,
										AmountInUnitsDecimal,
										UnitMargin,
										InitForexRate,
										SpreadedPipBid,
										SpreadedPipAsk,
										IsBuy,
										CloseOnEndOfWeek,
										EndOfWeekFee,
										OpenOccurred,
										CloseOccurred,
										ParentPositionID,
										OrigParentPositionID,
										MirrorID,
										IsOpenOpen,
										FullCommission,
										FullCommissionOnClose,
										RedeemStatus,
									    RedeemID,
										ReopenForPositionID,
										IsReOpen,
										CommissionOnCloseOrig,
										FullCommissionOnCloseOrig,
									    IsSettled,
								        InitialUnits,
										IsDiscounted,
									    CommissionByUnits,
									    FullCommissionByUnits,
										SettlementTypeID,
										DLTOpen,
                                        DLTClose,
		                                OpenMarkupByUnits
										)
	SELECT a.PositionID
			   ,a.CID
			   ,a.Leverage
			   ,0 as NetProfit
			   ,0 AS CommissionOnClose
			   ,a.Commission AS Commission
			   ,a.InstrumentID
			   ,COALESCE(a.Amount, 0) 
			   ,a.CurrencyID
			   ,a.ProviderID
			   ,a.HedgeID
			   ,a.HedgeServerID
			   ,a.AmountInUnitsDecimal
			   ,a.UnitMargin
			   ,a.InitForexRate
			   ,a.SpreadedPipBid
			   ,a.SpreadedPipAsk
			   ,a.IsBuy
			   ,a.CloseOnEndOfWeek
			   ,a.EndOfWeekFee
			   ,a.OpenOccurred
			   ,0 AS CloseOccurred
			   ,a.ParentPositionID
			   ,a.OrigParentPositionID
			   ,a.MirrorID
			   ,a.IsOpenOpen
			   ,COALESCE(a.FullCommission, 0.00)
			   , 0.00 FullCommissionOnClose
			   ,a.RedeemStatus
			   ,a.RedeemID
			   , a.ReopenForPositionID
			   , a.IsReOpen
			   , a.CommissionOnCloseOrig
			   , a.FullCommissionOnCloseOrig
			   , CAST(a.IsSettled AS INT)
			   , a.InitialUnits
			   , CAST(a.IsDiscounted AS INT)
			   , a.CommissionByUnits
			   , a.FullCommissionByUnits
			   , a.SettlementTypeID
			   , COALESCE(b.DLTOpen, a.DLTOpen)
               , COALESCE(b.DLTClose, a.DLTClose)
		       , COALESCE(b.OpenMarkupByUnits, a.OpenMarkupByUnits)
		  FROM dwh_daily_process.migration_tables.Ext_FCA_Real_Trade_Position a 
		  left join dwh_daily_process.migration_tables.Ext_FCA_History_Position b
		  on(a.PositionID=b.PositionID) 
		  where b.PositionID is null
		   

;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_RegulationIDOnOpen;
---Drop table if exists #RegulationIDOnOpen

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_RegulationIDOnOpen AS
Select * 
	
	from
	(
	Select CID, COALESCE(RegulationID, 0) as RegulationID,Occurred, 
	row_number() over (partition by CID order by Occurred desc) rn
	from dwh_daily_process.migration_tables.Ext_FCA_BackOffice_Customer
	) a
	where rn=1

;
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Position A_TGT USING (
SELECT * 
FROM TEMP_TABLE_RegulationIDOnOpen a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Position c ON a.CID = c.CID -----------------------


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY 1) = 1
)
ON a.CID = A_TGT.CID
WHEN MATCHED THEN UPDATE SET
RegulationIDOnOpen = COALESCE(a.RegulationID, 0);
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Position A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Real_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_Position_AirDrop b ON a.PositionID = b.PositionID --------------ReOpenPosition - Commission On Close
 --	DROP TABLE IF EXISTS #ReopenForPosition


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsAirDrop = 1;
DROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ReopenForPosition AS
select PositionID, ReopenForPositionID, CommissionOnClose,FullCommissionOnClose
  -- postions IsReOpen =1 for update  fron Trade
from dwh_daily_process.migration_tables.Ext_FCA_Real_Position
where IsReOpen = 1;


--create CLUSTERED INdex #ReopenForPosition on #ReopenForPosition(PositionID)

--	DROP TABLE IF EXISTS #PositionOrigin
DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;
-- Old position 

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionOrigin AS
SELECT a.PositionID, a.CommissionOnClose,a.FullCommissionOnClose
 -- Origin Commission 
from dwh_daily_process.migration_tables.Fact_CustomerAction  a 
JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Position b 
on a.PositionID = b.ReopenForPositionID
where  ActionTypeID in (4,5,6,28,40)  and a.DateID < V_dateID;

--  position close and reopen in same day
insert into TEMP_TABLE_PositionOrigin -- Origin Commission 
SELECT a.PositionID, a.CommissionOnClose,a.FullCommissionOnClose
from dwh_daily_process.migration_tables.Ext_FCA_Real_Position  a 
JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Position b 
on a.PositionID = b.ReopenForPositionID;

--create CLUSTERED INdex #PositionOrigin on #PositionOrigin(PositionID)
MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Position A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Real_Position a
INNER JOIN TEMP_TABLE_ReopenForPosition b on a.PositionID = b.PositionID -- postion for update 

INNER JOIN TEMP_TABLE_PositionOrigin c on b.ReopenForPositionID = c.PositionID -- data from origin position 


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
CommissionOnClose = b.CommissionOnClose - c.CommissionOnClose ,
FullCommissionOnClose = COALESCE(b.FullCommissionOnClose, 0) - COALESCE(c.FullCommissionOnClose, 0);
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction;
	/*OpenPositions*/
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , Leverage
										   , InstrumentID
										   , PositionID
										   , Commission
										   , DateID
										   , TimeID
										   , StatusID
										   , FullCommission
										   , FullCommissionOnClose
										   , RegulationIDOnOpen
										   , ReopenForPositionID
										   , IsReOpen
										   , SessionID
										   , MirrorID
										   , IsSettled
										   , InitialUnits
										   , IsDiscounted
										   , CommissionByUnits
										   , FullCommissionByUnits
										   , IsAirDrop
										   , SettlementTypeID
										   , DLTOpen
                                           , DLTClose
		                                   , OpenMarkupByUnits
										   , Description
										   )
	SELECT a.CID
		 , a.Occurred
		 , 1 AS IsReal
		 , CASE
			   WHEN d.PositionID is null THEN 39 /*PositionOpenTypeUnknown- need to fix at weekly maintenance*/

			   WHEN d.MirrorID = 0 AND COALESCE(d.OrigParentPositionID, 0) = 0 THEN
				   1
			   WHEN d.MirrorID > 0 AND COALESCE(d.OrigParentPositionID, 0) > 0 THEN
				   2
			   WHEN d.MirrorID = 0 AND COALESCE(d.OrigParentPositionID, 0) > 0 THEN
				   3
		   END AS ActionTypeID
		 ,0 AS PlatformTypeID
		 , COALESCE(a.TotalCashChange, 0)
		 , COALESCE(d.Leverage, 0)
		 , COALESCE(d.InstrumentID, 0)
		 , COALESCE(d.PositionID, 0)
		 , COALESCE(d.Commission, 0)
		 , CAST(date_format(a.Occurred, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from a.Occurred)
		 , 1
		 , d.FullCommission
		 , d.FullCommissionOnClose
		 , d.RegulationIDOnOpen
		 , d.ReopenForPositionID
		 , d.IsReOpen
		 , CASE 
		   WHEN d.MirrorID = 0 AND COALESCE(d.OrigParentPositionID, 0) = 0 then b.SessionID 
		   WHEN d.MirrorID > 0 AND COALESCE(d.OrigParentPositionID, 0) > 0 THEN e.SessionID
		   else null end as SessionID
		 , d.MirrorID
		 , CAST(IsSettled AS INT)
	     , InitialUnits
		 , CAST(IsDiscounted AS INT)
		 , CommissionByUnits
	     , FullCommissionByUnits
		 , IsAirDrop
		 , d.SettlementTypeID
		 , d.DLTOpen
         , d.DLTClose
		 , d.OpenMarkupByUnits
		 , a.Description
	FROM
		(SELECT *
		 FROM
			 dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All
		 WHERE
			 CreditTypeID = 3) a
		JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Position d
			ON (a.PositionID = d.PositionID )
			Left JOIN dwh_daily_process.migration_tables.Ext_FCA_Position_Session b
			on a.PositionID = b.PositionID
			Left JOIN dwh_daily_process.migration_tables.Ext_FCA_Mirror_Session e
			on d.MirrorID = e.MirrorID
	
	;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
WITH FULLSCAN;

	----***************************
	---- Fund All CopyPositionOPen

		--Drop Table IF EXISTS #CopyPositionOpen
DROP VIEW IF EXISTS TEMP_TABLE_CopyPositionOpen;

		CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_CopyPositionOpen AS
select a.PositionID, a.ParentPositionID
		
		from
		dwh_daily_process.migration_tables.Ext_FCA_Real_Position a
		left join dwh_daily_process.migration_tables.Ext_FCA_Real_Position b
		on a.ParentPositionID = b.PositionID
		where  a.ParentPositionID <>0;

		---- Fund All PositionOPen
		--Drop Table IF EXISTS #PositionOpenSessionID
DROP VIEW IF EXISTS TEMP_TABLE_PositionOpenSessionID;

		CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionOpenSessionID AS
select PositionID, SessionID
		
		from
		dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
		where  ActionTypeID in ( 1,2);

        --- Fill SessionID for ActionTypeID = 2 
	    MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT --(30709 rows affected)

USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction c
INNER JOIN TEMP_TABLE_CopyPositionOpen a on c.PositionID = a.PositionID and c.ActionTypeID = 2
INNER JOIN TEMP_TABLE_PositionOpenSessionID b on a.ParentPositionID = b.PositionID ----***************************
 /*ClosedPositions*/


QUALIFY ROW_NUMBER() OVER (PARTITION BY c.PositionID ORDER BY 1) = 1
)
ON c.PositionID = A_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
SessionID = b.SessionID;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction (RealCID , Occurred , IsReal , ActionTypeID , PlatformTypeID , Amount , InstrumentID , NetProfit , CommissionOnClose , Commission , PositionID , Leverage , DateID , TimeID , StatusID , FullCommission , FullCommissionOnClose , RedeemStatus , RedeemID , IsRedeem , RegulationIDOnOpen , ReopenForPositionID , IsReOpen , CommissionOnCloseOrig , FullCommissionOnCloseOrig , OriginalPositionID , IsPartialCloseChild , IsSettled , InitialUnits , IsDiscounted , CommissionByUnits , FullCommissionByUnits , IsAirDrop , SettlementTypeID , DLTOpen , DLTClose , OpenMarkupByUnits , `Description` ) SELECT a.CID , a.Occurred , 1 AS IsReal , CASE WHEN d.PositionID is null THEN 40 /*PositionCloseTypeUnknown- need to fix at weekly maintenance*/ WHEN d.MirrorID = 0 AND COALESCE(d.OrigParentPositionID, 0) = 0 THEN 4 WHEN d.MirrorID > 0 AND COALESCE(d.OrigParentPositionID, 0) > 0 THEN 5 WHEN d.MirrorID = 0 AND COALESCE(d.OrigParentPositionID, 0) > 0 THEN 6 WHEN d.MirrorID > 0 AND COALESCE(d.OrigParentPositionID, 0) = 0 THEN 28 ELSE 0 END AS ActionTypeID ,0 AS PlatformTypeID , COALESCE(a.TotalCashChange, 0) , COALESCE(d.InstrumentID, 0) , COALESCE(NetProfit, 0) , COALESCE(CommissionOnClose, 0) , COALESCE(Commission, 0) , COALESCE(a.PositionID, 0) , Leverage , CAST(date_format(a.Occurred, 'yyyyMMdd') AS INT) , EXTRACT(HOUR from a.Occurred) , 1 , COALESCE(d.FullCommission, 0) , COALESCE(d.FullCommissionOnClose, 0) , COALESCE(d.RedeemStatus, 0) , d.RedeemID , case when d.RedeemID is null then 0 else 1 end as IsRedeem , d.RegulationIDOnOpen , d.ReopenForPositionID , d.IsReOpen , d.CommissionOnCloseOrig , d.FullCommissionOnCloseOrig , d.OriginalPositionID , case when a.PositionID <> d.OriginalPositionID and d.OriginalPositionID is not null then 1 else 0 end IsPartialCloseChild , CAST(IsSettled AS INT) , InitialUnits , CAST(IsDiscounted AS INT) , CommissionByUnits , FullCommissionByUnits , IsAirDrop , d.SettlementTypeID , DLTOpen , DLTClose , OpenMarkupByUnits , a.Description FROM (SELECT CID , PositionID , Occurred , Payment , TotalCashChange , Description FROM dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All WHERE CreditTypeID = 4) a JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Position d ON (a.PositionID = d.PositionID)
	

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , PositionID
										   , DateID
										   , TimeID
										   , StatusID
										   , Description)
	SELECT CID
		 , a.Occurred
		 , 1 AS IsReal
		 , 32
		 ,0 AS PlatformTypeID
		 , COALESCE(TotalCashChange, 0)
		 , COALESCE(a.PositionID, 0)
		 , CAST(date_format(a.Occurred, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from a.Occurred)
		 , 1
		 , Description
	FROM
		(SELECT CID
			  , PositionID
			  , Occurred
			  , Payment
			  , TotalCashChange
			  , Description
		 FROM
			 dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All
		 WHERE
			 CreditTypeID = 13) a
		
;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , PositionID
										   , DateID
										   , TimeID
										   ,StatusID
										   ,MirrorID
										   ,IsFeeDividend
										   ,DividendID -- added by Geri 20140619
										   ,Description )

select
CID
, Occurred
, IsReal
, ActionTypeID
, PlatformTypeID
, Amount
, credit.PositionID
, DateID
, TimeID
,StatusID
,MirrorID
,IsFeeDividend
,DividendID
,Description
from
  ( Select ---564,210
       *,
       row_number() over (partition by PositionID, IsFeeDividend order by Occurred, Amount) rn
      from
		  (
			SELECT CID
				 , Occurred
				 , 1 AS IsReal
				 , 35 as ActionTypeID
				 , 0 AS PlatformTypeID
				 , COALESCE(TotalCashChange, 0) as Amount---- Changed from Payment by Geri 20140619
				 , COALESCE(a.PositionID, 0) as PositionID
				 , CAST(date_format(Occurred, 'yyyyMMdd') AS INT) as DateID
				 , EXTRACT(HOUR from Occurred) as TimeID
				 ,1 as StatusID
				 ,COALESCE(MirrorID, 0) as MirrorID -- added by Geri 20140619 
				 ,case when lower(Description) like '%dividend%' OR  Description  like '%divident%' then 2 
					   when Lower(Description) like '%sdrt%'  then 3
					   when Lower(Description) like '%opentotalfees%' or Lower(Description) like '%closetotalfees%' then 4
					   else 1 end as IsFeeDividend
				 , Description
			  FROM dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All a
			 WHERE
				CreditTypeID = 14
			) a
  ) credit
	left join
		(  select * ,
		    row_number() over (partition by PositionID order by ProcessTime, DividendValueInCurrency) rn--?? only dividends 
		     from dwh_daily_process.migration_tables.Ext_FCA_PositionsProcessedForIndexDividnds
		) dividnd
		on credit.PositionID = dividnd.PositionID 
		and credit.rn = dividnd.rn
		and IsFeeDividend =2;
		

	----SELECT CID
	----	 , Occurred
	----	 , 1 AS IsReal
	----	 , 35
	----	 , 0 AS PlatformTypeID
	----	 , isnull(TotalCashChange, 0) ---- Changed from Payment by Geri 20140619
	----	 , isnull(a.PositionID, 0)
	----	 , convert(INT, convert(VARCHAR, Occurred, 112))
	----	 , datepart (HOUR, Occurred)
	----	 ,1
	----	 ,isnull(MirrorID,0) -- added by Geri 20140619 
	----	 ,case when Description  like '%dividend%' OR  Description  like '%divident%' then 2 else 1 end as IsFeeDividend
	----	 ,NULL as DividendID
	----	-- ,case when Description  like '%dividend%' OR  Description  like '%divident%' then DividendID end as DividendID
	----FROM
	----	Ext_FCA_Real_History_Credit_ForFactAction_All a
	-------	left join [DWH_dbo].Ext_FCA_PositionsProcessedForIndexDividnds b
	------	on a.PositionID = b.PositionID
	----WHERE
	----	CreditTypeID = 14
	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , DurationInSeconds
										   , LoginID
										   , IPNumber
										   , DateID
										   , TimeID
										   , StatusID
										   , SessionID
										   , PlatformID)
	SELECT CID
		 , LoggedIn
		 , 1 AS IsReal
		 , 14 AS ActionTypeID
		 ,  ClientVersion		
		 , -1
		 , 0 as DurationInSeconds
		 --, CASE
			--   WHEN LoggedOut IS NOT NULL THEN
			--	   datediff(SECOND, LoggedIn, LoggedOut)
		 --  END
		 , LoginID
		 , case when INSTR(IP, ',') = 0 then COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(IP), 0)
				else COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(left(IP, INSTR(IP, ',')-1)), 0)
			end
		 , CAST(date_format(LoggedIn, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from LoggedIn)
		 , 1
		 ,SessionID
		 ,PlatformID
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Real_Audit_Loggin
	;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) SELECT 'Cashier| TIMESTAMP IS: ' || date_format(current_timestamp(), 'yyyy-MM-dd hh:mm:ss');
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , PositionID
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , CampaignID
										   , BonusTypeID
										   , FundingTypeID
										   , WithdrawID
										   , DepositID
										   , WithdrawPaymentID
										   , IPNumber
										   , DateID
										   , TimeID
										   , CompensationReasonID
										   , StatusID
										   , IsRedeem
										   , SessionID
										   , IsFTD
										   , MoveMoneyReasonID
										   , Description)
	SELECT a.CID
		 , a.Occurred
		 , a.PositionID
		 , 1 AS IsReal
		 , CASE --ActionTypeID
			  -- WHEN CreditTypeID = 1 AND c.FundingID = 5 THEN ---- Changed , not user table DWH.History.Ext_FCA_Real_Cashier_Deposit by Boris 20180208
				--   38 /*Affiliate Deposit*/
			   WHEN CreditTypeID = 1 and COALESCE(MoveMoneyReasonID, 0)<>5 THEN
				   7
			   WHEN CreditTypeID = 2 and COALESCE(MoveMoneyReasonID, 0)<>5 THEN
				   8
			   WHEN CreditTypeID = 6 THEN
				   36 
			   WHEN CreditTypeID = 7 THEN
				   9
			   WHEN CreditTypeID = 11 THEN
				   11
			   WHEN CreditTypeID = 12 THEN
				   12
			   WHEN CreditTypeID = 16 THEN
				   13
			  WHEN CreditTypeID = 29 THEN
				   34
			   WHEN CreditTypeID = 33 THEN
				   42
			   WHEN CreditTypeID = 32 THEN
				   43
			  WHEN CreditTypeID = 1 and MoveMoneyReasonID=5 THEN
				   44
			  WHEN CreditTypeID = 2 and MoveMoneyReasonID=5 THEN
				   45
		   END AS ActionTypeID
		 , CASE 
			   WHEN a.DepositID IS NOT NULL THEN 0
				   --CASE ---- Changed , not user table DWH.History.Ext_FCA_Real_Cashier_Deposit by Boris 20180208
					  -- WHEN FunnelID IN (7, 8, 9) THEN
						 --  2
					  -- WHEN FunnelID IN (20, 5) THEN
						 --  1
					  -- WHEN FunnelID = 6 THEN
						 --  3
					  -- ELSE
						 --  0
				   --END
			   WHEN a.WithdrawID IS NOT NULL THEN
				   2
			   ELSE
				   0
		   END AS PlatformTypeID
		 , COALESCE(CASE
WHEN CreditTypeID = 2 THEN
b.Amount
ELSE
a.Payment
END, 0) AS Amount
		 , COALESCE(CampaignID, 0)
		 , COALESCE(BonusTypeID, 0)
		 , CASE
			   WHEN a.DepositID IS NOT NULL THEN ---- Changed , not user table DWH.History.Ext_FCA_Real_Cashier_Deposit by Boris 20180208
				   COALESCE(d.FundingTypeID, COALESCE(dd.FundingTypeID, 0))
			   WHEN a.WithdrawID IS NOT NULL THEN
				   COALESCE(b.FundingTypeID, 0)
			   ELSE
				   0
		   END AS FundingType
		 , COALESCE(a.WithdrawID, 0)
		 , COALESCE(a.DepositID, 0)
		 , COALESCE(a.WithdrawPaymentID, 0)
		 , CASE
			  WHEN a.DepositID IS NOT NULL THEN ---- Changed , not user table DWH.History.Ext_FCA_Real_Cashier_Deposit by Boris 20180208
				   COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(d.IPAddress), 0)
			   WHEN a.WithdrawID IS NOT NULL THEN
				   COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(b.IPAddress), 0)
			   ELSE
				   0
		   END AS IPNumber
		 , CAST(date_format(Occurred, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from Occurred)
		 , COALESCE(CompensationReasonID, 0)
		 , 1
		 , case when CreditTypeID = 2 and b.FundingTypeID = 27 then 1 else 0 end as IsRedeem
		 , CASE WHEN CreditTypeID = 1 THEN d.SessionID else null end as SessionID
		 , CAST(d.IsFTD AS INT)
		 , MoveMoneyReasonID
		 , a.Description
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All a
		LEFT JOIN dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_CashoutToFunding b
			ON (a.WithdrawPaymentID = b.WithdrawPaymentID AND b.CashoutStatusID = 3) --WithdrawPaymentID (in [DWH_dbo].Fact_CustomerAction) = ID (in Billing.WithdrawToFuding) = WithdrawProccessingID (in History.Credit))
		--LEFT JOIN DWH.History.Ext_FCA_Real_Cashier_Deposit c ---- Changed , not user table DWH.History.Ext_FCA_Real_Cashier_Deposit by Boris 20180208
			--ON (a.DepositID = c.DepositID)
			----Left Join [DWH_dbo].Ext_FCA_Billing_Deposit_Session d
			----on a.DepositID = d.DepositID --> union to one table [DWH_dbo].Ext_FCA_Billing_Deposit
			Left Join dwh_daily_process.migration_tables.Ext_FCA_Billing_Deposit d
			on a.DepositID = d.DepositID and d.PaymentStatusID = 2
			Left Join dwh_daily_process.migration_tables.Ext_FCA_Billing_Deposit dd
			on a.DepositID = dd.DepositID and dd.PaymentStatusID = 11	
	WHERE
		CreditTypeID IN (1, 2, 6, 7, 11, 12, 16,29,33,32)
	;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_OldCOs;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OldCOs AS
SELECT CustomerActionID,WithdrawID,
	RANK() OVER (PARTITION BY WithdrawID ORDER BY Occurred) as Ranking
	
	FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
	WHERE ActionTypeID = 8
	AND (WithdrawPaymentID is null or WithdrawPaymentID = 0);

	--2. Get all successfull cashout payments (CashoutStatusID = 3) and rank by order
	--Drop table #OldWTF
DROP VIEW IF EXISTS TEMP_TABLE_OldWTF;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_OldWTF AS
SELECT WithdrawID, WithdrawPaymentID, Amount, IPAddress, FundingTypeID, 
	RANK() OVER (PARTITION BY WithdrawID ORDER BY ModificationDate) as Ranking
	
	FROM dwh_daily_process.migration_tables.Ext_FCA_Real_Cashier_CashoutToFunding
	WHERE CashoutStatusID = 3;

	--3. Update all missing fields with Payment, FundingType, and IP
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
INNER JOIN TEMP_TABLE_OldWTF ON dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction.WithdrawID = TEMP_TABLE_OldWTF.WithdrawID
INNER JOIN TEMP_TABLE_OldCOs ON dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction.CustomerActionID = TEMP_TABLE_OldCOs.CustomerActionID
)
ON TEMP_TABLE_OldCOs.Ranking = TEMP_TABLE_OldWTF.Ranking 
WHEN MATCHED THEN UPDATE SET
dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction.WithdrawPaymentID = TEMP_TABLE_OldWTF.WithdrawPaymentID ,
Ext_FCA_Fact_CustomerAction.Amount = TEMP_TABLE_OldWTF.Amount ,
Ext_FCA_Fact_CustomerAction.IPNumber = COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum ( TEMP_TABLE_OldWTF.IPAddress ), 0) ,
Ext_FCA_Fact_CustomerAction.FundingTypeID = TEMP_TABLE_OldWTF.FundingTypeID;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , WithdrawID
										   , IPNumber
										   , DateID
										   , TimeID
										   , Commission
										   , StatusID
										   , IsRedeem
										   , Description
										   )
	SELECT a.CID
		 , Occurred
		 , 1
		 , 10
		 , 2
		 , COALESCE(Amount, 0)
		 , COALESCE(a.WithdrawID, 0)
		 , COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(IPAddress), 0)
		 , CAST(date_format(Occurred, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from Occurred)
		 , Fee /*We Bring the CO fee only on Requset and processed CO in order to be able to calculate Unrealized fee*/
		 , 1
		 , case when FundingTypeID = 27 then 1 else 0 end as IsRedeem
		 , a.Description
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All  a
		join  
		dwh_daily_process.migration_tables.Ext_FCA_Tran_Billing_Withdraw b/*we use Tran_Billing_Withdraw  table and not History.Ext_FCABilling_Withdraw becuase we need Withdraws before the time of the run*/
		on(a.WithdrawID=b.WithdrawID)
		where CreditTypeID= 9 
	;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , WithdrawID
										   , IPNumber
										   , DateID
										   , TimeID
										   , Commission
										   , StatusID
										   , IsRedeem
										   , Description
										   )
	SELECT a.CID
		 , Occurred
		 , 1
		 , 37
		 , 2
		 , COALESCE(Amount, 0)
		 , COALESCE(a.WithdrawID, 0)
		 , COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(IPAddress), 0)
		 , CAST(date_format(Occurred, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from Occurred)
		 , Fee /*We Bring the CO fee only on Requset and processed CO in order to be able to calculate Unrealized fee*/
		 , 1
		 , case when FundingTypeID = 27 then 1 else 0 end as IsRedeem
		 , a.Description
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All  a
		join  
		dwh_daily_process.migration_tables.Ext_FCA_Tran_Billing_Withdraw b/*we use Tran_Billing_Withdraw  table and not History.Ext_FCABilling_Withdraw becuase we need Withdraws before the time of the run*/
		on(a.WithdrawID=b.WithdrawID)
		where CreditTypeID= 8 
		;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , WithdrawID
										   , IPNumber
										   , DateID
										   , TimeID
										   , StatusID
										   , Commission
										   , IsRedeem)
	SELECT CID
		 , ModificationDate
		 , 1
		 , 30
		 , 2
		 , COALESCE(Amount, 0)
		 , COALESCE(WithdrawID, 0)
		 , COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(IPAddress), 0)
		 , CAST(date_format(ModificationDate, 'yyyyMMdd') AS INT)
		 , EXTRACT(HOUR from ModificationDate)
		 , 1
		 , Fee
		 , case when FundingTypeID = 27 then 1 else 0 end as IsRedeem
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Billing_Withdraw b
	;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-----------	WHERE WithdrawID NOT in (SELECT WithdrawID from [DWH_dbo].Ext_Fact_CustomerAction_ActionTypeID_30  where DateID < @dateID )

----------	INSERT INTO [DWH_dbo].Ext_Fact_CustomerAction_ActionTypeID_30 (RealCID
----------											   , WithdrawID
----------											   , Occurred
----------												, DateID
----------)
----------	SELECT CID
----------		  , WithdrawID
----------		 , ModificationDate
----------		 , convert(INT, convert(VARCHAR, ModificationDate, 112))
----------	FROM
----------		[DWH_dbo].Ext_FCA_Billing_Withdraw b
----------	WHERE WithdrawID not in (SELECT WithdrawID from [DWH_dbo].Ext_Fact_CustomerAction_ActionTypeID_30 where DateID < @dateID)



	/*

	---------------
	Add Delete IN TABLE
	-----------


	*/

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction (RealCID , Occurred , IsReal , ActionTypeID , PlatformTypeID , Amount , PositionID , MirrorID , DateID , TimeID , StatusID ,SessionID , Description) SELECT CID , a.Occurred , 1 AS IsReal , CASE WHEN CreditTypeID = 18 THEN 15 WHEN CreditTypeID = 19 THEN 16 WHEN CreditTypeID = 20 THEN 17 WHEN CreditTypeID = 21 THEN 18 WHEN CreditTypeID = 27 THEN 19 WHEN CreditTypeID = 28 THEN 20 END , 0 AS PlatformTypeID , COALESCE(Payment, 0) AS Amount , COALESCE(a.PositionID, 0) , COALESCE(a.MirrorID, 0) , CAST(date_format(a.Occurred, 'yyyyMMdd') AS INT) , EXTRACT(HOUR from a.Occurred) , 1 ,case when CreditTypeID = 20 THEN b.SessionID else null end as SessionID , a.Description FROM dwh_daily_process.migration_tables.Ext_FCA_Real_History_Credit_ForFactAction_All a left join dwh_daily_process.migration_tables.Ext_FCA_Mirror_Session b on a.MirrorID = b.MirrorID WHERE CreditTypeID IN (18, 19, 20, 21, 27, 28)

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , PostRootID
										   , DateID
										   , TimeID
										   , StatusID)
	SELECT DC.CID  as RealCID
		 , Occurred
		 , 1
		 , Case EngagementType
			   When 'Discussion' Then 21
			   When 'Comment'	 Then 22
			   When 'Like'		 Then 23
		   End
		 , Case ApplicationName
				When 'OBdesktop' Then 1
				When 'OBMobile' Then 3
				When 'Openbook Mobile Proxy - Android' Then 5
				When 'Openbook Mobile Proxy - iOS' Then 7
				When 'WebTrader' Then 2
				Else 0
		   End
		 , -1
		 , PostRootID
		 , CAST(date_format(Occurred, 'yyyyMMdd') AS Int)
		 , EXTRACT(Hour from Occurred)
		 , 1
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_OpenBook_Engagement OBE 
		--Join DWH.[DWH_dbo].Dim_Customer DC With (Nolock) -------------------------- check with MAX, Double Table . [DWH_dbo].Extract Customer
		Join dwh_daily_process.migration_tables.Ext_FCA_Customer DC 
			--On Lower(Right(OBE.UserName,LENGTH(OBE.UserName)-1)) = Lower(DC.UserName) 
			On OBE.UserNameCalc =DC.UserNameCalc --
	;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , PaymentStatusID
										   , Amount
										   , DateID
										   , TimeID
										   , StatusID)
	SELECT CID  as RealCID
		 , ModificationDate
		 , 1
		 , 27 -- Deposit Attempt
		 , 0
		 , PaymentStatusID
		 , CASE WHEN Amount >= 1000000000 THEN 999999999 ELSE Amount END AS Amount
		 , CAST(date_format(ModificationDate, 'yyyyMMdd') AS Int)
		 , EXTRACT(Hour from ModificationDate)
		 , 1
	FROM
		dwh_daily_process.migration_tables.Ext_FCA_Deposit_Attempt  


	;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_Ext_FCA_Real_Audit_Loggin_MinDate;

		CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Ext_FCA_Real_Audit_Loggin_MinDate AS
select CID,PlatformID
		
		from
		(
		select CID,SessionID, a.PlatformID, ROW_NUMBER() OVER (PARTITION BY CID ORDER BY a.LoggedIn) AS RowNumber
		from dwh_daily_process.migration_tables.Ext_FCA_Real_Audit_Loggin a
		)b
		where RowNumber =1
;
		MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Real_Customer_Registration A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Real_Customer_Registration a
LEFT JOIN TEMP_TABLE_Ext_FCA_Real_Audit_Loggin_MinDate b on a.CID = b.CID
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
PlatformID = case when FunnelID = 36 and b.PlatformID = 103 then 104 when FunnelID = 36 and b.PlatformID = 109 then 110 when FunnelID = 36 then 117 when FunnelID = 42 then 111 when FunnelID = 43 then 105 when b.PlatformID = 116 then 117 --(reToro	Web	Browsers)
 when b.PlatformID = 109 then 110 --(reToro	Mobile	iOS)
 when b.PlatformID = 103 then 104 --(reToro	Mobile	Android)
 when b.PlatformID is not null then b.PlatformID end;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction 
(RealCID
										   , Occurred
										   , IsReal
										   , ActionTypeID
										   , PlatformTypeID
										   , Amount
										   , DateID
										   , TimeID
										   , StatusID
										   , PlatformID
										   , IPNumber
										   , CountryIDByIP
										   )

	SELECT CID
		  ,Registered
		  ,IsReal
		  ,ActionTypeID
		  ,PlatformTypeID
		  ,0
		  ,DateID
		  ,TimeID
		  ,1
		  ,PlatformID
		  ,case when INSTR(IP, ',') = 0 then COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(IP), 0)
				else COALESCE(dwh_daily_process.migration_tables.IPAddressToIPNum(left(IP, INSTR(IP, ',')-1)), 0)
			end
	     , CountryIDByIP
	  FROM dwh_daily_process.migration_tables.Ext_FCA_Real_Customer_Registration
	;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_Customer b ON ( a.RealCID = b.CID ) 
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
GCID = b.GCID ,
DemoCID = 0;

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) UPDATE dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction SET HistoryID = case when GCID =-1 /**/ then CAST(cast(4 AS STRING) + cast(IsReal AS STRING) + right('00' + cast(ActionTypeID AS STRING), 2) + right('00' + cast(PlatformTypeID AS STRING), 2) + right('0000000000' + cast(RealCID AS STRING), 10) AS DECIMAL(38)) else CAST(cast(4 AS STRING) + cast(IsReal AS STRING) + right('00' + cast(ActionTypeID AS STRING), 2) + right('00' + cast(PlatformTypeID AS STRING), 2) + right('0000000000' + cast(GCID AS STRING), 10) AS DECIMAL(38))

		-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
TRUNCATE tABLE dwh_daily_process.migration_tables.Ext_FCA_ActionTypeID_14


;
		INSERT INTO dwh_daily_process.migration_tables.Ext_FCA_ActionTypeID_14
           (`SessionID`
           ,`PlatformID`
           ,`DateID`)
		SELECT
			`SessionID`
           ,`PlatformID`
           ,`DateID`
		from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
		where ActionTypeID = 14


;
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_ActionTypeID_14 b on a.SessionID = b.SessionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.SessionID ORDER BY 1) = 1
)
ON a.SessionID = A_TGT.SessionID
WHEN MATCHED THEN UPDATE SET
dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction.PlatformID = b.PlatformID;
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction lg
INNER JOIN dwh_daily_process.migration_tables.Ext_FCA_CountryIP di ON lg.IPNumber BETWEEN di.IPFrom AND di.IPTo
)
ON lg.IPNumber is not null and lg.IPNumber <> 0 ------- Update Anonymous IP 

WHEN MATCHED THEN UPDATE SET
CountryIDByIP = di.CountryID;
	MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction lg
INNER JOIN dwh_daily_process.migration_tables.Dim_CountryIPAnonymous di ON lg.IPNumber BETWEEN di.IPFrom AND di.IPTo
)
ON lg.IPNumber is not null and lg.IPNumber <> 0 ------ Session Id for 
 /*
1. 17 - Register new mirror.
2. 2 - CopyPositionOpen.   
3. 1 - ManualPositionOpen.
4. 7 - Deposit.  
*/
 --drop table If EXISTS #ActionTypeIDsRealCID

WHEN MATCHED THEN UPDATE SET
CountryIDByIP = di.CountryID ,
IsAnonymousIP = 1 ,
ProxyType = di.ProxyType;
DROP VIEW IF EXISTS TEMP_TABLE_ActionTypeIDsRealCID;

    CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ActionTypeIDsRealCID AS
SELECT Distinct RealCID
    
    from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
    where (ActionTypeID in (1,2,7,17) and  (SessionID  = 0 or SessionID is null or SessionID = -1 or PlatformID is null));

    -- found SessionID for action type LogIN
   -- drop table If EXISTS #ActionTypeID14SessionID
DROP VIEW IF EXISTS TEMP_TABLE_ActionTypeID14SessionID;

    CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ActionTypeID14SessionID AS
select RealCID, SessionID, PlatformID, Occurred,ActionTypeID
    
    from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
    where ActionTypeID  =14 and  RealCID in (select RealCID from TEMP_TABLE_ActionTypeIDsRealCID);

    -- found relevant data for update
    insert into TEMP_TABLE_ActionTypeID14SessionID
		   Select RealCID, SessionID, PlatformID, Occurred,ActionTypeID
   from
   (
    select RealCID, SessionID, PlatformID, Occurred,ActionTypeID, 
	ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY Occurred desc,SessionID desc) AS RN
    from dwh_daily_process.migration_tables.Fact_CustomerAction
    where ActionTypeID  =14 and  RealCID in (select RealCID from TEMP_TABLE_ActionTypeIDsRealCID)
    and DateID >= V_dateID14daysAgo and DateID < V_dateID
	)a where RN=1;

    ------select RealCID, SessionID, PlatformID, Occurred,ActionTypeID
    ------from [DWH_dbo].Fact_CustomerAction
    ------where ActionTypeID  =14 and  RealCID in (select RealCID from #ActionTypeIDsRealCID)
    ------and DateID >= @dateID14daysAgo

    -- Found rows for update
    --drop table If EXISTS #ActionTypeIDsSessionID
DROP VIEW IF EXISTS TEMP_TABLE_ActionTypeIDsSessionID;

    CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ActionTypeIDsSessionID AS
select RealCID, SessionID, PlatformID, Occurred,ActionTypeID, DepositID, PositionID, MirrorID
    
    from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction
    where ActionTypeID in (1,2,7,17) and  (SessionID  = 0 or SessionID is null or SessionID = -1 or PlatformID is null) 
	and RealCID in (select RealCID from TEMP_TABLE_ActionTypeIDsRealCID);

   -- drop table If EXISTS #UpdateSession
DROP VIEW IF EXISTS TEMP_TABLE_UpdateSession;
-- data for update

    CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_UpdateSession AS
select
    RealCID, PlatformID, SessionID,DepositID, PositionID, MirrorID
    
    from
    (
    select *
        ,ROW_NUMBER() OVER (PARTITION BY RealCID,DepositID, PositionID, MirrorID ORDER BY Occurred) AS RN
        from
    (
        select a.RealCID, a.PlatformID, a.SessionID, a.Occurred, DATEDIFF(SECOND, b.Occurred, a.Occurred) DiffSecond ,DepositID, PositionID, MirrorID
    from TEMP_TABLE_ActionTypeID14SessionID a
    left join TEMP_TABLE_ActionTypeIDsSessionID b
    on a.RealCID = b.RealCID
    and
    a.Occurred<=b.Occurred
    --where b.ActionTypeID = 7
    ) a
    ) b
    where RN = 1;

    -- run script to update MirrorID ActionTypeID in (17)
    MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction a
INNER JOIN TEMP_TABLE_UpdateSession b on a.RealCID = b.RealCID AND a.MirrorID = b.MirrorID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY 1) = 1
)
ON a.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
PlatformID = b.PlatformID ,
SessionID = b.SessionID;
    MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction a
INNER JOIN TEMP_TABLE_UpdateSession b on a.RealCID = b.RealCID AND a.DepositID = b.DepositID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY 1) = 1
)
ON a.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
PlatformID = b.PlatformID ,
SessionID = b.SessionID;
    MERGE INTO dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FCA_Fact_CustomerAction a
INNER JOIN TEMP_TABLE_UpdateSession b on a.RealCID = b.RealCID AND a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY 1) = 1
)
ON a.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
PlatformID = b.PlatformID ,
SessionID = b.SessionID;
END;
