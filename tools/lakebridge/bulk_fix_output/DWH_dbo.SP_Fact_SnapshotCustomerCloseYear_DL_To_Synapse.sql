USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS


BEGIN


DECLARE V_CurrentDate  TIMESTAMP;
--DECLARE @DateTime as DATETIME2(7)
--DECLARE @CurrentDateTime as DATETIME2(7)History.Credit
--SET @Date = cast(@dt as date)
--SET @DateTime = CAST(@dt as DATETIME2);
--SET @CurrentDate = DATEADD(DAY, DATEDIFF(DAY,-1,@Date), 0);
DECLARE V_MaxSnapshot  date
;
DECLARE V_Year STRING 
;
DECLARE V_St_Year STRING 
;
--feature/Fact_SnapshotCustomer-adf
/********************************************************************************************
Author:      Daniel Kaplan
Date:        2021-08-24
Description: SP intended to transfer data from DataLake to synapse
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2022-12-28		Inbal		Add columns: PhoneNumber, IsPhoneVerified, PhoneVerificationDateID and PlayerStatusSubReasonID to Extract tables
 2022-02-09	    Inbal		Remove Delete statment for rerun
 2024-04-01		Inbal		Add WeekendFeePrecentage to [DWH_dbo].Ext_FSC_Real_Customer_CustomerCloseYear
 2024-04-16		Inbal		Remove Update statment for rerun
 2025-03-18     Adi Ferber    Replace Ext_FSC_PhoneVerificationDetailsCloseYear with Ext_FSC_PhoneCustomerCloseYear - new DB and new table with all the phone details 
 2025-10-29     Daniel Kaplan Add new DLT, FTD fields , create a [DWH_dbo].[Ext_FSC_DimCustomerCloseYear] table

*********************************************************************************************/


--EXEC [DWH_dbo].[SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse] '2025-01-01'

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    

	-- DECLARE @dt as [Date] = '2023-01-01'
	
	
	
	--DECLARE @Date as DATETIME

SET V_CurrentDate = cast(DATEADD(day, DATEDIFF(-1, V_dt), 0) as date);
	--SET @CurrentDateTime = cast(dateadd(day,datediff(day,-1,@dt),0) as DATETIME2)-- Sequence Container - Fact_SnapshotCustomer
SET V_Year = year(V_dt)
;
SET V_St_Year = convert(TIMESTAMP,DATEADD(YEAR, CAST(DATEDIFF(0, V_dt) / 365 AS INT), 0),8);

-- Delete from [DWH_dbo].Fact_SnapshotCustomer  --------------------------------------->

--select @MaxSnapshot = MAX(convert(datetime,left(convert(varchar(16),DateRangeID),8)))
--from [DWH_dbo].Fact_SnapshotCustomer (nolock)
--WHERE LEFT(DateRangeID,4) = convert(INT,@Year)

--if @MaxSnapshot >= @dt
--BEGIN


----Delete For rerun - Delete all the rows that in DateRangeID the FromDate is @dt 

--Delete from [DWH_dbo].Fact_SnapshotCustomer 
--where
--left(DateRangeID,4) = year(@dt)
--and CONVERT(datetime, convert(varchar(8), left(DateRangeID,8)))>=@dt


----Update DateRangeID For rerun ---------------------------------------> Update all max DateRangeID for each CID to be the end of the year	

--Update a
--set DateRangeID = convert(varchar(8),left(DateRangeID,8)) || '1231'
--from [DWH_dbo].Fact_SnapshotCustomer as a
--inner join (
--select RealCID, max(DateRangeID) maxDateRangeID
--from [DWH_dbo].Fact_SnapshotCustomer 
--where
--left(DateRangeID,4) = year(@dt)
--group by RealCID
--) b on a.RealCID = b.RealCID and a.DateRangeID = b.maxDateRangeID
--where right(a.DateRangeID,4) <> '1231'

--END


--truncate table [DWH_dbo].Ext_FSC_BackOffice_Customer
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_BackOffice_CustomerCloseYear

;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_BackOffice_CustomerCloseYear
(`CID`, `VerificationLevelID`, `RiskStatusID`, `RiskClassificationID`, `EmployeeAccount`, `GuruStatusID`, `AccountTypeID`, `RegulationID`, 
`AccountManagerID`, `Occurred`,  `DocumentStatusID`, `SuitabilityTestStatusID`, `MifidCategorizationID`, `DesignatedRegulationID`, `EvMatchStatus`)
select 
CID,
VerificationLevelID,
RiskStatusID,
RiskClassificationID,
`EmployeeAccount`,
GuruStatusID,
AccountTypeID,
RegulationID,
`AccountManagerID`,
Occurred,
DocumentStatusID,
SuitabilityTestStatusID,
MifidCategorizationID,
DesignatedRegulationID,
EvMatchStatus
from
(
select 
b.ValidFrom as Occurred,
b.CID,
b.VerificationLevelID,
b.RiskStatusID,
b.RiskClassificationID,
--b.isEmployeeAccount,
0 as `EmployeeAccount`,
b.GuruStatusID,
b.AccountTypeID,
b.RegulationID,
b.ManagerID as `AccountManagerID`,
b.DocumentStatusID,
b.SuitabilityTestStatusID, 
b.MifidCategorizationID,
b.DesignatedRegulationID,
b.EvMatchStatus,
 rn
from dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomerCloseYear b 
--------[History].[BackOfficeCustomer]  b with (nolock)
------where  b.[ValidFrom] < @CurrentDate --DATEADD(day,datediff(day,-1,@dt),0)
) k
where rn =1;


--truncate table [DWH_dbo].Ext_FSC_Real_Customer_Customer
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_CustomerCloseYear;

--Extract Ext_FSC_Real_Customer_Customer
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_CustomerCloseYear
(`GCID`, `CID`, `UserName`, `Gender`, `BirthDate`, `CountryID`, `AffiliateID`, `CampaignID`, `LabelID`, `LanguageID`, `Email`, `PlayerStatusID`, `PlayerLevelID`, 
`CommunicationLanguageID`, `AccountStatusID`, `Occurred`, `PendingClosureStatusID`, `IsEmailVerified`, `RegionID`, `PlayerStatusReasonID` , City,	Address,	Zip , PlayerStatusSubReasonID,WeekendFeePrecentage)
select 
GCID,
CID,
UserName,
Gender,
BirthDate,
CountryID,
`AffiliateID`,
CampaignID,
LabelID,
LanguageID,
Email,
PlayerStatusID,
PlayerLevelID,
CommunicationLanguageID,
AccountStatusID,
Occurred,
PendingClosureStatusID,
CAST(IsEmailVerified AS INT),
RegionID,
PlayerStatusReasonID,
City,	Address,	Zip,
PlayerStatusSubReasonID,
WeekendFeePrecentage
from
(
SELECT
b.GCID,
b.CID,
b.UserName,
b.Gender,
b.BirthDate,
b.CountryID,
b.SerialID AS `AffiliateID`,
b.CampaignID,
b.LabelID,
b.LanguageID,
b.Email,
b.PlayerStatusID,
b.PlayerLevelID,
b.CommunicationLanguageID,
b.AccountStatusID,
b.ValidFrom as  Occurred,
b.PendingClosureStatusID,
CAST(IsEmailVerified AS INT),
RegionID,
PlayerStatusReasonID,
City,	Address,	Zip,
PlayerStatusSubReasonID,
WeekendFeePrecentage,
rn 
  FROM dwh_daily_process.daily_snapshot.etoro_History_CustomerCloseYear  b  
  --[History].[Customer] b with (nolock)
 ------ where 
 ------ b.GCID is not null
	------AND b.[ValidFrom] < @CurrentDate --DATEADD(day,datediff(day,-1,@dt),0)
) a
where rn = 1;


----truncate table [DWH_dbo].Ext_FSC_Real_History_Credit
--truncate table [DWH_dbo].Ext_FSC_Real_History_Credit

----Extract Ext_FSC_Real_History_Credit

--INSERT INTO [DWH_dbo].Ext_FSC_Real_History_Credit
--([CID], [Occurred], [Credit], [Payment], [TotalCashChange], [CreditTypeID], [CashoutID], [CampaignID], [PositionID], [DepositID], [WithdrawID], [PaymentID], 
--[BonusTypeID], [MirrorID], [CompensationReasonID], [WithdrawPaymentID], [BonusCredit], [CreditID], [RealizedEquity], [TotalCash])
--SELECT 
--	   CID
--	 , Occurred
--	 , Credit
--	 , Payment
--	 , TotalCashChange
--	 , CreditTypeID
--	 , CashoutID
--	 , CampaignID
--	 , PositionID
--	 , DepositID
--	 , WithdrawID
--	 , PaymentID
--	 , BonusTypeID
--	 , MirrorID
--     , CompensationReasonID
--	 , WithdrawProcessingID
--	 , BonusCredit
--	 , CreditID
--     , RealizedEquity
--     , TotalCash
--FROM
--(
--SELECT CID
--	 , Occurred
--	 , Credit
--	 , Payment
--	 , TotalCashChange
--	 , CreditTypeID
--	 , CashoutID
--	 , CampaignID
--	 , PositionID
--	 , DepositID
--	 , WithdrawID
--	 , PaymentID
--	 , BonusTypeID
--	 , MirrorID
--     , CompensationReasonID
--	 , WithdrawProcessingID
--	 , isnull(BonusCredit,0) as BonusCredit
--	 , CreditID
--     , RealizedEquity
--     , TotalCash
--	 , row_number() over(partition by CID, convert(int,convert(varchar,Occurred,112)) order by Occurred desc, CreditID desc) as rn
--FROM  [DWH_staging].[etoro_History_ActiveCredit]  with (nolock)  
--	--History.ActiveCredit WITH (NOLOCK)
--where Occurred >= @dt 
--AND  Occurred <  @CurrentDate --@CurrentDate --DATEADD(day,datediff(day,-1,@dt),0) 
----b.[ValidFrom] >= @Date --@dt
----AND b.[ValidFrom] < @CurrentDate 
----DATEADD(day,datediff(day,-1,@dt),0)

--AND CreditTypeID = 1 
--) a
--where rn = 1


----truncate table [DWH_dbo].Ext_FSC_IsDepositorCloseYear
--truncate table [DWH_dbo].Ext_FSC_IsDepositorCloseYear

----Extract Ext_FSC_IsDepositorCloseYear

--INSERT INTO [DWH_dbo].Ext_FSC_IsDepositorCloseYear
--(CID, IsDepositor)
--select CID, 1 [IsDepositor]
--from
--(
--Select  CID,
-- rn 
--FROM [DWH_staging].[etoro_History_CreditCloseYear] With (Nolock)
----Where 
----Occurred < @CurrentDate
----And CreditTypeID = 1
--) a
--where 
--rn = 1


--truncate table [DWH_dbo].Ext_FSC_PhoneVerificationDetailsCloseYear
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomerCloseYear;

--Extract Ext_FSC_PhoneCustomerCloseYear
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomerCloseYear
(GCID,
 CID ,
 PhoneNumber,
 PhoneVerifiedID,
 PhoneVerificationDate,
 PhoneVerificationDateID ,
 StartTime,
 EndTime)
Select  phone.GCID,
		customer.CID ,
		phone.PhoneNumber,
		phone.PhoneVerifiedID,
		phone.PhoneVerificationDate,
		phone.PhoneVerificationDateID ,
		phone.StartTime,
		phone.EndTime
FROM dwh_daily_process.daily_snapshot.ContactVerification_History_PhoneCustomerCloseYear phone 
join dwh_daily_process.daily_snapshot.etoro_Customer_Customer customer on customer.GCID=phone.GCID;

--truncate table [DWH_dbo].[Ext_FSC_DimCustomerCloseYear]
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_DimCustomerCloseYear;

--Extract [DWH_dbo].[Ext_FSC_DimCustomerCloseYear]
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_DimCustomerCloseYear
(GCID
,RealCID
,IsDepositor
,DltStatusID 
,DltID 
,EquiLendID 
,StocksLendingStatusID
,UpdateDate)
select 
GCID
,RealCID
,IsDepositor
,DltStatusID 
,DltID 
,EquiLendID 
,StocksLendingStatusID
,UpdateDate
from dwh_daily_process.migration_tables.Dim_Customer
where (YEAR(current_timestamp()) = YEAR(UpdateDate)
OR YEAR(current_timestamp()) = YEAR(UpdateDate) - 1 )
AND (
COALESCE(CAST(IsDepositor AS BOOLEAN), FALSE) <> 0 OR
DltStatusID  IS NOT NULL OR
DltID  IS NOT NULL OR
EquiLendID  IS NOT NULL OR
StocksLendingStatusID IS NOT NULL )

;
call dwh_daily_process.migration_tables.SP_Fact_SnapshotCustomerCloseYear(V_dt);
END;
