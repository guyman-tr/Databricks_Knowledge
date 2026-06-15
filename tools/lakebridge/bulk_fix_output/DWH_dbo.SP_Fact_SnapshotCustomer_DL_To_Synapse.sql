USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_SnapshotCustomer_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

--exec [DWH_dbo].[SP_Fact_SnapshotCustomer_DL_To_Synapse] '20250226'
BEGIN


DECLARE V_Date  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_DateTime  timestamp
;
DECLARE V_CurrentDateTime  timestamp
;
DECLARE V_MaxSnapshot  date
;
DECLARE V_Year STRING 
;
DECLARE V_St_Year STRING;
--SET @Date = cast(@dt as date)
--feature/Fact_SnapshotCustomer-adf
-- =============================================
-- Author:     Daniel Kaplan
-- Create Date: 2021-08-24
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].Fact_SnapshotCustomer '20210718' 
-- ====================Ext_FSC_Real_Customer_Customer=========================
--EXEC [DWH_dbo].[SP_Fact_SnapshotCustomer_DL_To_Synapse] '2025-07-22'

/********************************************************************************************
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2022-11-28     Inbal         Create Ext_FSC_PhoneVerificationDetails
 2022-12-28		Inbal		  Add PlayerStatusSubReasonID to Ext_FSC_Real_Customer_Customer 
 2022-02-09	    Inbal		  Remove Delete statment for rerun
 2024-04-01		Inbal		  Add WeekendFeePrecentage to [DWH_dbo].Ext_FSC_Real_Customer_Customer
 2024-04-16		Inbal		  Remove Update statment for rerun
 2025-03-18     Adi Ferber    Replace Ext_FSC_PhoneVerificationDetails with Ext_FSC_PhoneCustomer - new DB and new table with all the phone details 
 2025-06-03     Daniel Kaplan Replace Ext_FSC_Real_History_Credit with Ext_FSC_Customer_FirstTimeDeposits - new DB and new table with all FTD details 
*********************************************************************************************/

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    

	--DECLARE @dt as [Date] = cast(getdate()-1 as date)

	-- DECLARE @dt as [Date] = '2024-04-02'

SET V_DateTime = CAST(V_dt as timestamp);
--SET @CurrentDate = DATEADD(DAY, DATEDIFF(DAY,-1,@Date), 0);

SET V_CurrentDate = cast(DATEADD(day, DATEDIFF(-1, V_dt), 0) as date);
	--SET @CurrentDateTime = cast(dateadd(day,datediff(day,-1,@dt),0) as DATETIME2)
	-- Sequence Container - Fact_SnapshotCustomer
SET V_Year = year(V_dt)
;
SET V_St_Year = convert(TIMESTAMP,DATEADD(YEAR, CAST(DATEDIFF(0, V_dt) / 365 AS INT), 0),8);

----Delete and update for rerun
-- Delete from [DWH_dbo].Fact_SnapshotCustomer  --------------------------------------->

--select @MaxSnapshot = MAX(convert(datetime,left(convert(varchar(16),DateRangeID),8)))
--from [DWH_dbo].Fact_SnapshotCustomer (nolock)
--WHERE LEFT(DateRangeID,4) = convert(INT,@Year)

--Select @MaxSnapshot, @dt,@Year

--if @MaxSnapshot >= @dt
--BEGIN

--Delete from [DWH_dbo].Fact_SnapshotCustomer 
--where
--left(DateRangeID,4) = year(@dt)
--and CONVERT(datetime, convert(varchar(8), left(DateRangeID,8)))>=@dt

-- Update DateRangeID  --------------------------------------->	

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


-- Truncate Ext_FSC_BackOffice_RegulationChangeLog --------------------------------------->
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog;
	
-- Extract Ext_FSC_BackOffice_RegulationChangeLog
DROP VIEW IF EXISTS TEMP_TABLE_etoro_History_BackOfficeCustomer;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_etoro_History_BackOfficeCustomer AS
Select  *
  -- Move duplicates rows, because two parquet files with another dates
from
(
select
CID,
RegulationID,
ValidFrom,
ValidTo,
CustomerHistoryID,
ROW_NUMBER() over (partition by a.CID, CustomerHistoryID  order by a.ValidTo ) as rn
from dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer a 
) a
where  rn =1


;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog
SELECT
RegulationChangeID,
CID,
Occurred,
FromRegulationID,
ToRegulationID,
DateID
from
(
select
100000 as RegulationChangeID,
a.CID,
MAX(b.Max_ValidFrom) as Occurred,
COALESCE(c.RegulationID, 0)  as FromRegulationID,
COALESCE(a.RegulationID, 0) as ToRegulationID,
CAST(date_format(DATEADD(day, 0, b.Max_ValidFrom), 'yyyyMMdd') AS int) as DateID,
ROW_NUMBER() over (partition by a.CID order by a.ValidTo desc) as rn,a.ValidTo
from  TEMP_TABLE_etoro_History_BackOfficeCustomer a 
--[DWH_staging].[etoro_History_BackOfficeCustomer] a WITH (nolock)
--[History].[BackOfficeCustomer] a with (nolock)
join
(
SELECT CID, MAX(ValidFrom) AS Max_ValidFrom, MAX(ValidTo) AS Max_ValidTo
FROM   TEMP_TABLE_etoro_History_BackOfficeCustomer 
---[DWH_staging].[etoro_History_BackOfficeCustomer] with (nolock)
--[History].[BackOfficeCustomer] with (nolock)
where 
ValidFrom  >= V_dt 
and ValidFrom < V_CurrentDate  --cast(dateadd(day,datediff(day,-1,@dt),0) as date)
GROUP BY CID
) b
on a.CID=b.CID  and a.ValidFrom = b.Max_ValidFrom and a.ValidTo = b.Max_ValidTo
join
(
SELECT a.CID , b.Max_ValidFrom, b.Max_ValidTo, RegulationID
from TEMP_TABLE_etoro_History_BackOfficeCustomer a 
---[DWH_staging].[etoro_History_BackOfficeCustomer] a WITH (nolock)
--[History].[BackOfficeCustomer] a with (nolock)
join
(
SELECT CID, max(ValidFrom) AS Max_ValidFrom, max(ValidTo) AS Max_ValidTo
FROM TEMP_TABLE_etoro_History_BackOfficeCustomer 
---[DWH_staging].[etoro_History_BackOfficeCustomer] with (nolock)
--[History].[BackOfficeCustomer] with (nolock)
where ValidFrom  < V_dt
group by CID
) b
on a.CID= b.CID and  ValidFrom = b.Max_ValidFrom and ValidTo = b.Max_ValidTo																																												
) c
on a.CID = c.CID
WHERE
a.RegulationID <> c.RegulationID
AND a.ValidFrom >= V_dt 
AND ValidFrom < V_CurrentDate  --cast(dateadd(day,datediff(day,-1,@dt),0) as date)
group by
a.CID,
COALESCE(c.RegulationID, 0),
COALESCE(a.RegulationID, 0),
CAST(date_format(DATEADD(day, 0, b.Max_ValidFrom), 'yyyyMMdd') AS int),
 a.ValidTo
 ) g
where rn = 1;


	----------------------------------------------------------------->
-- truncate table [DWH_dbo].Ext_FSC_BackOffice_RegulationChangeLog_All
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog_All;

--insert into [DWH_dbo].Ext_FSC_BackOffice_RegulationChangeLog_All([RegulationChangeID]
insert into dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog_All
(`RegulationChangeID`
              ,`CID`
              ,`Occurred`
              ,`FromRegulationID`
              ,`ToRegulationID`
              ,`DateID`
              )
select   a.`RegulationChangeID`
   ,a.`CID`
   ,a.`Occurred`
   ,b.`FromRegulationID`
   ,a.`ToRegulationID`
   ,a.`DateID`
from 
(
SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,`ToRegulationID`
  ,DateID
from 
(SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,`ToRegulationID`
  ,DateID
  ,row_number() over(partition by CID,DateID order by Occurred desc ) as rn
  FROM (SELECT  `RegulationChangeID`
      ,`CID`
      ,`Occurred`
      ,COALESCE(`FromRegulationID`, 0) as FromRegulationID
      ,COALESCE(`ToRegulationID`, 0) as  ToRegulationID
     ,CAST(date_format(DATEADD(day, 0, `Occurred`), 'yyyyMMdd') AS int) as DateID
     FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog
    ) a
 ) b
where rn=1
) a
join 
(
SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,DateID
from 
(SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,COALESCE(`FromRegulationID`, 0) as FromRegulationID
  ,COALESCE(`ToRegulationID`, 0) as  ToRegulationID
  ,DateID
  ,row_number() over(partition by CID,DateID order by Occurred ) as rn
  FROM (SELECT `RegulationChangeID`
     ,`CID`
     ,`Occurred`
     ,`FromRegulationID`
     ,`ToRegulationID`
     ,CAST(date_format(DATEADD(day, 0, `Occurred`), 'yyyyMMdd') AS int) as DateID
     FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog     
    ) a
 ) b
where rn=1
) b
on(a.CID=b.CID and a.DateID=b.DateID)
where b.FromRegulationID<> a.ToRegulationID;


--truncate table [DWH_dbo].Ext_FSC_BackOffice_Customer
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_BackOffice_Customer

;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_BackOffice_Customer
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
b.`ValidFrom` as Occurred,
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
row_number() over (partition by CID order by ValidFrom desc ,ValidTo desc) rn
from dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer b 
--[History].[BackOfficeCustomer]  b with (nolock)
where 
b.`ValidFrom` >= V_dt
AND b.`ValidFrom` < V_CurrentDate --DATEADD(day,datediff(day,-1,@dt),0)
) k
where rn =1;


--truncate table [DWH_dbo].Ext_FSC_Real_Customer_Customer
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer;

--Extract Ext_FSC_Real_Customer_Customer
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer
(`GCID`, `CID`, `UserName`, `Gender`, `BirthDate`, `CountryID`, `AffiliateID`, 
`CampaignID`, `LabelID`, `LanguageID`, 
`Email`, `PlayerStatusID`, `PlayerLevelID`, 
`CommunicationLanguageID`, `AccountStatusID`, `Occurred`, 
`PendingClosureStatusID`, `IsEmailVerified`, `RegionID`, `PlayerStatusReasonID`,
`City`,`Address`,`Zip`,`PlayerStatusSubReasonID`,`WeekendFeePrecentage`
)
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
`City`,`Address`,`Zip`,PlayerStatusSubReasonID,
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
b.`ValidFrom` as  Occurred,
b.PendingClosureStatusID,
CAST(b.IsEmailVerified AS int) as IsEmailVerified,
RegionID,
PlayerStatusReasonID,
`City`,`Address`,`Zip`,PlayerStatusSubReasonID,
WeekendFeePrecentage,
ROW_NUMBER() over(Partition By b.`CID`,cast (b.`ValidFrom` as date)  order by  b.`ValidFrom` desc, b.`CustomerVersionID` desc) as rn 
  FROM dwh_daily_process.daily_snapshot.etoro_History_Customer  b  
  --[History].[Customer] b with (nolock)
  where 
  b.GCID is not null
  and
	b.`ValidFrom` >= V_dt
	AND b.`ValidFrom` < V_CurrentDate --DATEADD(day,datediff(day,-1,@dt),0)
) a
where rn = 1;

--truncate table [DWH_dbo].Ext_FSC_Real_History_Credit
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_Real_History_Credit;

--Extract Ext_FSC_Real_History_Credit
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_Real_History_Credit
(`CID`, `Occurred`, `Credit`, `Payment`, `TotalCashChange`, `CreditTypeID`, `CashoutID`, `CampaignID`, `PositionID`, `DepositID`, `WithdrawID`, `PaymentID`, 
`BonusTypeID`, `MirrorID`, `CompensationReasonID`, `WithdrawPaymentID`, `BonusCredit`, `CreditID`, `RealizedEquity`, `TotalCash`)
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
     , CompensationReasonID
	 , WithdrawProcessingID
	 , BonusCredit
	 , CreditID
     , RealizedEquity
     , TotalCash
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
     , CompensationReasonID
	 , WithdrawProcessingID
	 , COALESCE(BonusCredit, 0) as BonusCredit
	 , CreditID
     , RealizedEquity
     , TotalCash
	 , row_number() over(partition by CID, CAST(date_format(Occurred, 'yyyyMMdd') AS int) order by Occurred desc, CreditID desc) as rn
FROM  dwh_daily_process.daily_snapshot.etoro_History_ActiveCredit    
	--History.ActiveCredit WITH (NOLOCK)
where Occurred >= V_dt 
AND  Occurred <  V_CurrentDate --@CurrentDate --DATEADD(day,datediff(day,-1,@dt),0) 
--b.[ValidFrom] >= @Date --@dt
--AND b.[ValidFrom] < @CurrentDate 
--DATEADD(day,datediff(day,-1,@dt),0)

AND CreditTypeID = 1 
) a
where rn = 1;

--FTD : [DWH_dbo].Ext_FSC_Customer_FirstTimeDeposits --------------------- 
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FSC_Customer_FirstTimeDeposits
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_Customer_FirstTimeDeposits
	(
		`GCID` ,
		`CID` 	
	)
	select distinct FTD.`Gcid`,	cus_stg.`CID` as CID
	from  dwh_daily_process.daily_snapshot.CustomerFinanceDB_Customer_FirstTimeDeposits FTD
	LEFT JOIN dwh_daily_process.daily_snapshot.etoro_Customer_Customer cus_stg
		ON FTD.Gcid = cus_stg.GCID;

	--select distinct FTD.[GCID],	isnull(cus_stg.[CID],cus.[RealCID]) as CID
	--from  [DWH_staging].[CustomerFinanceDB_Customer_FirstTimeDeposits] FTD
	--LEFT JOIN [DWH_staging].[etoro_History_Customer] cus_stg
	--	ON FTD.GCID = cus_stg.GCID
	--LEFT JOIN [DWH_dbo].[Dim_Customer] cus
	----[DWH_dbo].Ext_FSC_Real_Customer_Customer cus
	--	ON FTD.GCID = cus.GCID

-------------------------------PhoneCustomer----------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomer;

--Extract Ext_FSC_PhoneCustomer
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomer
(GCID,CID, PhoneNumber, PhoneVerifiedID, PhoneVerificationDate, PhoneVerificationDateID , StartTime , EndTime )
SELECT
   phone.GCID
  ,customer.CID
  ,phone.PhoneNumber
  ,phone.VerificationStatusID as PhoneVerifiedID
  ,phone.VerificationDate AS PhoneVerificationDate
  ,CAST(date_format(phone.VerificationDate, 'yyyyMMdd') AS INT) AS PhoneVerificationDateID
  ,phone.`ValidFrom` as StartTime	
  ,phone.`ValidTo` as EndTime
FROM  dwh_daily_process.daily_snapshot.ContactVerification_Phone_Customer phone
join dwh_daily_process.daily_snapshot.etoro_Customer_Customer customer on customer.GCID=phone.GCID
where  ValidFrom>= V_dt AND ValidFrom<  V_CurrentDate;

-------------------------------StocksLending-------------------------------------
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSC_StocksLending;

--Extract Ext_FSC_StocksLending
INSERT INTO dwh_daily_process.migration_tables.Ext_FSC_StocksLending
(CID, GCID, EquiLendID, ConsentDateTime, StocksLendingStatusID, BeginTime, EndTime)
SELECT
   customer.CID,	
   customer.GCID, 
   EquiLendID, 
   ConsentDateTime, 
   StocksLendingStatusID, 
   BeginTime, 
   EndTime
FROM  dwh_daily_process.daily_snapshot.ComplianceStateDB_Compliance_StocksLending stocks
join dwh_daily_process.daily_snapshot.etoro_Customer_Customer customer on customer.GCID=stocks.GCID
where  BeginTime>= V_dt AND BeginTime<  V_CurrentDate;
-----------------------------------------------------------------------------------
call dwh_daily_process.migration_tables.SP_Fact_SnapshotCustomer(V_dt);
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_etoro_History_BackOfficeCustomer;
END;
