BEGIN


DECLARE V_Date  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_DateTime  timestamp
;
DECLARE V_CurrentDateTime  timestamp;
--SET @Date = cast(@dt as date)
DECLARE V_MaxSnapshot  date
;
DECLARE V_Year STRING ;

DECLARE V_St_Year STRING ;
--feature/Fact_SnapshotEquity-adf
-- =============================================
-- Author:     Daniel Kaplan
-- Create Date: 2021-08-24
-- Description: SP intended to transfer data from DataLake to synapse
-- =============================================
/***************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
27/01/2022     Inbal BML     add SettlementTypeID
09/01/2024     Inbal BML	 change [DWH_staging].[etoro_Trade_Position] to [DWH_staging].[etoro_Trade_OpenPositionEndOfDay] and [DWH_staging].[etoro_History_Position] to [DWH_staging].[etoro_History_ClosePositionEndOfDay]
11/11/2024     Daniel K      add LotCountDecimal to dwh_daily_process.migration_tables.Ext_FSE_Trade_Position and dwh_daily_process.migration_tables.Ext_FSE_History_Position for futures
29/09/2025     Daniel K      add Stock Margin to dwh_daily_process.migration_tables.Ext_FSE_Trade_Position and dwh_daily_process.migration_tables.Ext_FSE_History_Position:InitForexRate, AmountInUnitsDecimal
10/12/2025     Daniel K      add Stock Margin to dwh_daily_process.migration_tables.Ext_FSE_Trade_Position and dwh_daily_process.migration_tables.Ext_FSE_History_Position:InitConversionRate
**********************************************************************************************************************/
--EXEC [DWH_dbo].[SP_Fact_SnapshotEquity_DL_To_Synapse] '2025-09-08'

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    

	--DECLARE @dt as [Date] = '2021-12-18'

SET V_DateTime = CAST(V_dt as timestamp);
--SET @CurrentDate = DATEADD(DAY, DATEDIFF(DAY,-1,@Date), 0);

SET V_CurrentDate = CAST(DATEADD(DAY, 1, CAST(V_dt AS DATE)) AS DATE);
	--SET @CurrentDateTime = cast(dateadd(day,datediff(day,-1,@dt),0) as DATETIME2)-- Sequence Container - Fact_SnapshotEquity
-- Check Date Equity Snapshot --------------------------------------->
SET V_Year = year(V_dt)
;
SET V_St_Year = CAST(DATE_TRUNC('YEAR', CAST(V_dt AS DATE)) AS STRING);
--SELECT ISNULL(MAX(convert(datetime,left(convert(varchar(16),DateRangeID),8))), @St_Year) as max
--from [DWH_dbo].Fact_SnapshotEquity
--where
--left(DateRangeID,4) = @Year
-- Delete from [DWH_dbo].Fact_SnapshotEquity  --------------------------------------->

SET V_MaxSnapshot = (
SELECT
MAX(CAST(left(CAST(DateRangeID AS STRING),8) AS TIMESTAMP)) from dwh_daily_process.migration_tables.Fact_SnapshotEquity
WHERE LEFT(DateRangeID,4) = V_Year

 LIMIT 1);
IF V_MaxSnapshot >= V_dt
THEN
Delete from dwh_daily_process.migration_tables.Fact_SnapshotEquity 
where
left(DateRangeID,4) = year(V_dt)
and CAST(CAST(left(DateRangeID,8) AS STRING) AS TIMESTAMP)>=V_dt;


-- Update DateRangeID  --------------------------------------->	
MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity a_TGT
USING (
WITH
b as ( select CID , max ( DateRangeID ) maxDateRangeID from dwh_daily_process.migration_tables.Fact_SnapshotEquity where left ( DateRangeID , 4 ) = year ( V_dt ) group by CID )
SELECT * 
from dwh_daily_process.migration_tables.Fact_SnapshotEquity a
INNER JOIN b on a.CID = b.CID and a.DateRangeID = b.maxDateRangeID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY 1) = 1
)
ON a.CID = a_TGT.CID
WHEN MATCHED THEN UPDATE SET
DateRangeID = CAST(left ( DateRangeID , 8 ) AS STRING) || '1231';
END IF;

-- Truncate Ext_FSE_InProcessCashouts  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_InProcessCashouts;

-- Truncate Ext_FSE_InProcessCashouts  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawToFundingAction;


-- Extract Ext_FSE_History_WithdrawToFundingAction  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawToFundingAction
SELECT WithdrawID, BW2F_ID, ModificationDate,CashoutStatusID, WithdrawToFundingActionID
from dwh_daily_process.daily_snapshot.etoro_History_WithdrawToFundingAction;
--History.WithdrawToFundingAction with (NOLOCK)

-- Truncate Ext_FSE_History_WithdrawAction  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction

;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction
SELECT WithdrawID, WithdrawActionID, ModificationDate, CashoutStatusID
FROM dwh_daily_process.daily_snapshot.etoro_History_WithdrawAction;
--from History.WithdrawAction

-- Truncate Ext_FSE_Billing_WithdrawToFunding  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_Billing_WithdrawToFunding;

-- Extract Ext_FSE_History_WithdrawAction  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Billing_WithdrawToFunding
SELECT WithdrawID, ID, Amount
from dwh_daily_process.daily_snapshot.etoro_Billing_WithdrawToFunding;
--Billing.WithdrawToFunding

-- Truncate Ext_FSE_Billing_Withdraw  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw;

-- Extract Ext_FSE_Billing_Withdraw  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw
SELECT CID, Amount, Fee, CashoutStatusID, ModificationDate, RequestDate, WithdrawID
from dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw;

--Billing.Withdraw with (NOLOCK)

-- Truncate Ext_FSE_TotalCashChangeAll  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_TotalCashChangeAll;

-- Extract Ext_FSE_TotalCashChangeAll  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_TotalCashChangeAll
select CID, sum(TotalCashChange) as TotalCashChangeAll 
from dwh_daily_process.daily_snapshot.etoro_History_ActiveCredit 
--History.ActiveCredit WITH (NOLOCK)
where Occurred >= V_dt and  Occurred < V_CurrentDate
group by CID;

-- Truncate Ext_FSE_Real_History_Credit  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_Real_History_Credit;

-- Extract Ext_FSE_Real_History_Credit  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Real_History_Credit
(	   CID
	 , Occurred
	 , Credit
	 , Payment
	 , TotalCashChange
	 , CreditTypeID
	 , CashoutID
	 , CampaignID
	 , PositionID
	 , DepositID
	 , WithdrawID
	 , PaymentID
	 , BonusTypeID
	 , MirrorID
	 , `WithdrawPaymentID`
	 , BonusCredit
	 , CreditID
     , CompensationReasonID
     , RealizedEquity
     , TotalCash)
SELECT 
CID
	 , Occurred
	 , Credit
	 , Payment
	 , TotalCashChange
	 , CreditTypeID
	 , CashoutID
	 , CampaignID
	 , PositionID
	 , DepositID
	 , WithdrawID
	 , PaymentID
	 , BonusTypeID
	 , MirrorID
	 , WithdrawProcessingID
	 , COALESCE(BonusCredit, 0) as BonusCredit
	 , CreditID
     , CompensationReasonID
     , RealizedEquity
     ,0 as  TotalCash
FROM
(
SELECT CID
	 , Occurred
	 , Credit
	 , Payment
	 , TotalCashChange
	 , CreditTypeID
	 , CashoutID
	 , CampaignID
	 , PositionID
	 , DepositID
	 , WithdrawID
	 , PaymentID
	 , BonusTypeID
	 , MirrorID
	 , WithdrawProcessingID
	 , COALESCE(BonusCredit, 0) as BonusCredit
	 , CreditID
     , CompensationReasonID
     , cast(RealizedEquity as decimal(16,2)) as RealizedEquity
     ,0 as  TotalCash
	 , row_number() over(partition by CID, CAST(date_format(Occurred, 'yyyyMMdd') AS int) order by Occurred desc, CreditID desc) as rn
from dwh_daily_process.daily_snapshot.etoro_History_ActiveCredit 
--History.ActiveCredit WITH (NOLOCK)
where Occurred >= V_dt and  Occurred < V_CurrentDate
) a
where rn = 1;

-- exec [DWH_dbo].SP_Fact_SnapshotEquity_InProcessCashouts  --------------------------------------->	
call dwh_daily_process.migration_tables.sp_fact_snapshotequity_inprocesscashouts_autopoc(V_dt);
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_History_Position;

-- Extract Ext_FSE_History_Position  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_History_Position
(PositionID,MirrorID,CID,InstrumentID,TotalPositions, IsSettled, InstrumentTypeID,Leverage,ParentPositionID,InitialAmount,SettlementTypeID,LotCountDecimal,
InitForexRate, AmountInUnitsDecimal,InitConversionRate)
Select	PositionID,MirrorID,CID,HP.InstrumentID,Amount as TotalPositions, cast(IsSettled as int)   as IsSettled,  b.`InstrumentTypeID`,Leverage,ParentPositionID
,`InitialAmountCents`/100 as InitialAmount,SettlementTypeID
,HP.LotCountDecimal --2024-11-11 for futures 
--2025-09-29 for Stock Margin
,HP.InitForexRate
,HP.AmountInUnitsDecimal
,HP.InitConversionRate
	from  dwh_daily_process.daily_snapshot.etoro_History_ClosePositionEndOfDay HP
	--[History].[Position] HP with(nolock)
		left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
		--[Trade].[GetInstrument] b 
	on HP.InstrumentID = b.InstrumentID
	Where
 HP.CloseOccurred >= DATEADD(day, 1, V_dt) AND HP.OpenOccurred <DATEADD(day, 1, V_dt);
 ---and PositionID  = OriginalPositionID 


-- DROP INDEX Ext_FSE_Trade_Position  --------------------------------------->	
-- [stub] Synapse IF EXISTS(sys.*) ... DROP elided -- UC has no sys.* catalog
-- Truncate Ext_FSE_Trade_Position  --------------------------------------->	

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_Trade_Position;

-- Extract Ext_FSE_Trade_Position  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_Trade_Position
(PositionID,MirrorID,CID,InstrumentID,TotalPositions, IsSettled, InstrumentTypeID,Leverage,ParentPositionID,InitialAmount,SettlementTypeID,LotCountDecimal,
InitForexRate, AmountInUnitsDecimal,InitConversionRate)
Select PositionID,MirrorID,CID,a.InstrumentID,Amount as TotalPositions, cast(IsSettled as int)   as IsSettled,  b.`InstrumentTypeID`,Leverage,ParentPositionID
,`InitialAmountCents`/100 as InitialAmount,SettlementTypeID
,a.LotCountDecimal --2024-11-11 for futures 
--2025-09-29 for Stock Margin
,a.InitForexRate
,a.AmountInUnitsDecimal
,a.InitConversionRate
	From dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay a 
	--[Trade].[Position] a with(nolock)
	left join dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
	--[Trade].[GetInstrument] b 
	on a.InstrumentID = b.InstrumentID
	where Occurred<DATEADD(day, 1, V_dt);


-- CREATE INDEX Ext_FSE_Trade_Position  --------------------------------------->	
  
-- [stub] MERGE-with-empty-ON elided (Synapse index rebuild has no UC equivalent)

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog;

-- Extract Ext_FSE_PositionChangeLog  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog
(PositionID,CID,Occurred,IsSettled,PreviousIsSettled)
select 
PositionID,
CID,
Occurred,
Cast(IsSettled as int) IsSettled,
cast(PreviousIsSettled as int ) PreviousIsSettled
from
(
select
pl.PositionID
,pl.CID
,Occurred
,CAST(pl.IsSettled AS INT)
,CAST(pl.PreviousIsSettled AS INT)
, ROW_NUMBER() over (partition by pl.PositionID order by  pl.Occurred ) rn
from dwh_daily_process.daily_snapshot.etoro_History_PositionChangeLog pl 
--[History].[PositionChangeLog_Active] pl with (NOLOCK)
where Occurred >= DATEADD(DAY, 1, CAST(V_dt AS DATE))
---and isnull(CAST(pl.IsSettled AS INT),-1) <> isnull(CAST(pl.PreviousIsSettled AS INT),-1)
and COALESCE(Cast(pl.IsSettled as int), 0)<> COALESCE(Cast(pl.PreviousIsSettled as int), 0)
 and  ChangeTypeID  =13 ---Edit Is Settled
) a
where rn =1;

-- Truncate Ext_FSE_History_Credit  --------------------------------------->	
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSE_History_Credit;

-- Extract Ext_FSE_History_Credit  --------------------------------------->	
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_History_Credit
select PositionID,sum(-TotalCashChange) as Amount
from dwh_daily_process.daily_snapshot.etoro_History_Credit 
--[History].[Credit] with(nolock)
where CreditTypeID=13 and Occurred >= V_CurrentDate
group by PositionID;

-- Exec [DWH_dbo].SP_Fact_SnapshotEquity_TotalPositionAmount  --------------------------------------->	
call dwh_daily_process.migration_tables.sp_fact_snapshotequity_totalpositionamount_autopoc(V_dt);
call dwh_daily_process.migration_tables.sp_fact_snapshotequity_autopoc(V_dt);
END