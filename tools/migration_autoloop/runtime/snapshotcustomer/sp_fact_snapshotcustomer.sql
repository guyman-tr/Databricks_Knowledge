BEGIN



DECLARE V_auxdate  TIMESTAMP
;
DECLARE V_daybefore   TIMESTAMP
;
DECLARE V_largedate   TIMESTAMP
;
DECLARE V_maxentrydate   TIMESTAMP
;
DECLARE V_ProcessName   STRING
;
DECLARE V_minCreditID  Int
;
DECLARE V_maxCreditID  INT
;
DECLARE V_dateID INT ;

DECLARE V_row_count INT 
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-03-11
Description: Update table Fact_SnapshotCustomer - Process one to update table Fact_SnapshotCustomer
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2020-02-23     Boris         Add column  IsCreditReportValidCB
 2020-02-15     Boris		  Change case for IsCreditReportValidCB + IsValidCustomer  from 2020.03.16
 2022-04-03     Boris         Add filter to #outputdata left(DateRangeID),4) = YEAR(@date)
 2022-11-28	    Inbal         Add Columns: PhoneNumber, IsPhoneVerified and PhoneVerificationDateID to Fact_SnapshotCustomer
 2022-12-28		Inbal		  Add PlayerStatusSubReasonID to Fact_SnapshotCustomer
 2023-02-01		Inbal		  Add PhoneNumber to GDPR
 2024-04-01		Inbal		  Add WeekendFeePrecentage to Fact_SnapshotCustomer
 2024-08-13		Nir.H		  Add DltStatusID,DltID to Fact_SnapshotCustomer
 2024-09-08		Nir.H		  DltID add default  null
 2024-10-06     Eyal.B        FIX DltID update logic
 2024-10-13     Eyal.B	      FFIX DltID update logic to get the data to Fact_SnapshotCustomer
 2024-10-15     Eyal.B		  DltID final fix including additional tmp table
 2024-10-21     Eyal.B		  Fix DltID - prevent the deletion of DLT when having new snapshot
 2024-10-29     Eyal.B		  Fix DltID - Again, New user support
 2025-03-18     Adi Ferber    Replace Ext_FSC_PhoneVerificationDetails with Ext_FSC_PhoneCustomer - new DB and new table with all the phone details  
 2025-05-11     Eyal Boas     Add EquiLendID + StocksLendingStatusID
 2025-06-03     Daniel Kaplan Replace Ext_FSC_Real_History_Credit with Ext_FSC_Customer_FirstTimeDeposits - new DB and new table with all FTD details 
*********************************************************************************************/

/*** Important note:
This is the script that runs every day and fills up Fact_SnapshotCustomer_DEV using ETL tables.
If you're looking to load history use SP_History_Fact_SnapshotCustomer_DEV

**Create temp tables:
This script works using two lead tables - CC and BO.
The process:
-Make a list of all CIDs from CC stage table with Operation = 2 (NewCIDs) and another with Operation = 4 (Exist CIDs - update to CC) from stage tables (will be used later). When we insert, we will only insert the most updated row regardless of operation.
-Take most recent entry for each CID from CC for our day
-Take most recent entry for each CID from BC and RegulationTransfer for our day
-Combine BC and Regulations using Full JOIN between them, another left join to CustomerSnapshot and also use isnull in SELECT.
-Combine BC and CC using Full JOIN between them, another left join to CustomerSnapshot and use isnull in SELECT.

**Insert data
-Insert all rows that CIDs match #NewCIDs with ToDate=End of year
-Update all rows that CIDs in #ExistCIDs ToDate=Yesterday
-Insert new rows for all entries in #ExistCIDs with FromDate=Today, and ToDate=EndOfYear

**Insert new DateIDs to dim

**Close of year - Close of all last year's open entries and reopen them for this year.

--Explanation for RegulationChangeLog:
We take the RegulationID from RegulationChangeLog and not from BC because the change date from RegulationChangeLog is the end of day,
and from BC the change is effective immdediately. For business reasons regulation change on END OF DAY, so we need to take this field from Fact_RegulationChangeLog.
***/

--DECLARE @date AS DATE = '2025-06-05'

SET V_dateID = CAST(date_format(V_date, 'yyyyMMdd') AS int)
;
SET V_daybefore = DATEADD(DAY, -1, V_date)
;
SET V_auxdate = DATEADD(DAY, 1, V_date)
;
SET V_largedate = (
				  SELECT cast(cast(year(V_date) AS STRING) || '12' || '31' AS TIMESTAMP)
				 )
;
SET V_maxentrydate = (
					 SELECT CASE
								WHEN month(V_date) = 01 AND day(V_date) = 01
									THEN DATEADD(YEAR, -1, V_largedate)
								ELSE V_largedate
							END
					) --Set max entry date as last year's if we're on the 01/01
;
SET V_ProcessName = 'Fact_SnapshotCustomer';

--print @largedate
--print @maxentrydate
--print @date
--select DateRangeID , convert(bigint,left(convert (Varchar(20),DateRangeID),8)+right(convert (Varchar,@daybefore,112),4)) from [DWH_dbo].[Fact_SnapshotCustomer]
/****************************************************************Fill Ext_FSC tables*********************************************************************************/

/**Fill temp tables with most updated rows only per CID **/

/**** IMPORTANT ****/
--Note: #NewCIDs and #ExistCIDs will be used in the insert/update process, but only the most updated row (regardless of operation number) will be inserted.
--Since there could be a an operation 2 (insert) and a 4 (update) for the same CID in a certain day, we will only want the #4 in this case.

--Get a list of all new inserted CIDs
--DROP TABLE #NewCIDs
DROP VIEW IF EXISTS TEMP_TABLE_NewCIDs;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_NewCIDs AS
SELECT distinct t.CID

FROM dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer t 
	left join
	dwh_daily_process.migration_tables.Fact_SnapshotCustomer f
	on 
	t.CID = f.RealCID
where f.RealCID is null; --First day that they were inserted

--Get a list of all Existing CIDs in Ext_FSC table
--DROP TABLE #ExistCIDs
DROP VIEW IF EXISTS TEMP_TABLE_ExistCIDs;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ExistCIDs AS
SELECT DISTINCT (t.CID)

FROM (
	  SELECT CID
	  FROM dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer a 
	  UNION
	  SELECT CID
	  FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_Customer b 
	  UNION
	  SELECT CID
	  FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog c 
	  	 ) t
WHERE t.CID NOT IN (
					SELECT CID
					FROM TEMP_TABLE_NewCIDs
				   ); --All CIDs that didn't have an operation = 2 (insert) today


--Get most recent entry for each CID from CC in our day
--DROP TABLE #CCTemp
DROP VIEW IF EXISTS TEMP_TABLE_CCTemp;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_CCTemp AS
SELECT *

FROM (
	  SELECT
		   t.GCID
		   , t.CID
		   , t.UserName
		   , t.Gender
		   , t.BirthDate
		   , t.CountryID
		   , t.AffiliateID
		   , t.CampaignID
		   , t.LabelID
		   , t.LanguageID
		   , t.Email
		   , t.PlayerStatusID
		   , t.PlayerLevelID
		   , t.CommunicationLanguageID
		   , t.AccountStatusID
		   , t.Occurred AS ValidFrom
		   , t.PendingClosureStatusID
		   , CAST(t.IsEmailVerified AS INT)
		   , t.RegionID
           , t.PlayerStatusReasonID
		   , t.City
		   , t.Address
		   , t.Zip
		   , t.PlayerStatusSubReasonID
		   , t.WeekendFeePrecentage
		   , row_number() OVER (PARTITION BY t.CID ORDER BY t.Occurred DESC) AS RowNum --Latest Insert or update per CID
	  FROM dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer t 
	 ) AS tt
WHERE tt.RowNum = 1;


--Get most updated row from BC
--DROP TABLE #BCTemp
DROP VIEW IF EXISTS TEMP_TABLE_BCTempNoReg;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_BCTempNoReg AS
SELECT *

FROM (
	  SELECT-- t.LSN
		   --, t.Operation
		   --, 
		   t.CID
		   , t.VerificationLevelID
		   , t.RiskStatusID
		   , t.RiskClassificationID
		   , t.EmployeeAccount
		   , t.GuruStatusID
		   , t.AccountTypeID
		   , COALESCE(t.RegulationID, 0) AS RegulationID
		   , t.AccountManagerID AS ManagerID
		   , t.DocumentStatusID
		   , t.SuitabilityTestStatusID
		   , t.MifidCategorizationID
		   , t.DesignatedRegulationID
		   , t.EvMatchStatus
		   , row_number() OVER (PARTITION BY t.CID ORDER BY t.Occurred DESC) AS RowNum
	  FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_Customer t 

	 ) AS tt
WHERE tt.RowNum = 1;
--Note - A user is always created in CC before BC so the user will already exist in snapshot once we insert its BC data
--Note - We select the RegulationID in BC for new users

--Get most recent regulation changes from today
DROP VIEW IF EXISTS TEMP_TABLE_RegulationChanges;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_RegulationChanges AS
SELECT *

FROM (
	  SELECT t.CID
		   , COALESCE(t.ToRegulationID, 0) AS ToRegulationID
		   , row_number() OVER (PARTITION BY t.CID ORDER BY t.Occurred DESC) AS RowNum --The occurred may be of the day before, but that okay because we change regulation only at the end of day and the DateKey reflects the end of day
	  FROM dwh_daily_process.migration_tables.Ext_FSC_BackOffice_RegulationChangeLog t 

	 ) AS tt
WHERE tt.RowNum = 1;

--Combine BO Customer with RegulationChanges with FULL JOIN and get missing data from SnapshotCustomer
DROP VIEW IF EXISTS TEMP_TABLE_BCTemp;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_BCTemp AS
SELECT COALESCE(TEMP_TABLE_BCTempNoReg.CID, TEMP_TABLE_RegulationChanges.CID) AS CID
	 , TEMP_TABLE_BCTempNoReg.VerificationLevelID AS VerificationLevelID
	 , TEMP_TABLE_BCTempNoReg.RiskStatusID AS RiskStatusID
	 , TEMP_TABLE_BCTempNoReg.RiskClassificationID AS RiskClassificationID
	 , TEMP_TABLE_BCTempNoReg.GuruStatusID AS GuruStatusID
	 , TEMP_TABLE_BCTempNoReg.AccountTypeID AS AccountTypeID
	 , TEMP_TABLE_BCTempNoReg.ManagerID AS ManagerID
	 , TEMP_TABLE_RegulationChanges.ToRegulationID AS RegulationID
	 , TEMP_TABLE_BCTempNoReg.RegulationID AS RegulationIDBackup --If FromRegulationID exists in RegulationChangeLog take it, else take it from Snapshot, else take it from History.BackOffice customer (that means that it's a new customer). We shouldn't take it from BOCustomer right away b/c the regulation might have changed during the day but will be in effect only on end of day.
	 , TEMP_TABLE_BCTempNoReg.DocumentStatusID AS DocumentStatusID
	 , TEMP_TABLE_BCTempNoReg.SuitabilityTestStatusID AS SuitabilityTestStatusID
	 , TEMP_TABLE_BCTempNoReg.MifidCategorizationID AS MifidCategorizationID
	 , TEMP_TABLE_BCTempNoReg.DesignatedRegulationID AS DesignatedRegulationID
	 , TEMP_TABLE_BCTempNoReg.EvMatchStatus AS EvMatchStatus

FROM TEMP_TABLE_BCTempNoReg
	FULL JOIN TEMP_TABLE_RegulationChanges --Full Join them = even if one of the tables is null b/c there wasn't a change
		ON TEMP_TABLE_RegulationChanges.CID = TEMP_TABLE_BCTempNoReg.CID;


-- Get all users who made a deposit today

--If Object_ID('tempdb..#TodayDepositors','U') Is Not Null 
--   drop table #TodayDepositors

--Select Distinct CID
--Into #TodayDepositors
--FROM dwh_daily_process.migration_tables.Ext_FSC_Customer_FirstTimeDeposits
DROP VIEW IF EXISTS TEMP_TABLE_DepositorChanges;
-- Join with SnapshotCustomer to find only the users who should be updated

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_DepositorChanges AS
Select TD.CID , 1 as IsDepositor

From dwh_daily_process.migration_tables.Ext_FSC_Customer_FirstTimeDeposits TD
	--#TodayDepositors TD
	Left Join dwh_daily_process.migration_tables.Fact_SnapshotCustomer FSC 
		ON FSC.RealCID = TD.CID AND CAST(left(CAST(FSC.DateRangeID AS STRING), 4) + right(CAST(FSC.DateRangeID AS STRING), 4) AS TIMESTAMP) = 
		(
		case when  DATEADD(YEAR, CAST(DATEDIFF(0, current_timestamp()) / 365 AS INT), 0) =  V_date then V_date 
		else 
		V_maxentrydate --Take most updated row from Customer Snapshot
		end
		)
Where	COALESCE(CAST(FSC.IsDepositor AS BOOLEAN), FALSE) = 0;

/*
Select Distinct CID
Into #TodayDepositors
From [DWH_dbo].Ext_FSC_Real_History_Credit With (Nolock)
-- Where CreditTypeID = 1  in Extract

-- Join with SnapshotCustomer to find only the users who should be updated

If Object_ID('tempdb..#DepositorChanges','U') Is Not Null 
   drop table #DepositorChanges

Select TD.CID, 1 IsDepositor
Into #DepositorChanges
From 
	#TodayDepositors TD
	Left Join [DWH_dbo].Fact_SnapshotCustomer FSC With (Nolock)
		ON FSC.RealCID = TD.CID AND convert(DATETIME, left(convert(VARCHAR(16), FSC.DateRangeID), 4) + right(convert(VARCHAR(16), FSC.DateRangeID), 4)) = 
		(
		case when  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) =  @date then @date 
		else 
		@maxentrydate --Take most updated row from Customer Snapshot
		end
		)
Where
	Isnull(FSC.IsDepositor,0) = 0
*/

---------------------------------------------------#PhoneVerificationDetails
DROP VIEW IF EXISTS TEMP_TABLE_PhoneVerificationDetails;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PhoneVerificationDetails 
    
AS
	SELECT	 CID
			,PhoneNumber
			,CASE WHEN PhoneVerifiedID IN (1, 2) THEN 1 ELSE 0 END AS IsPhoneVerified
			,PhoneVerificationDate 
			,PhoneVerificationDateID
			 FROM dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomer
			 WHERE PhoneVerificationDateID <> 19000101;

			 			 			
----------------------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification_DLT
	
;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification_DLT
(GCID, CID, DemoCID, TanganyID,	UpdateDate,	TanganyStatusID,DltID , DltStatusID)
SELECT GCID, CID, DemoCID, TanganyID,	UpdateDate,	TanganyStatusID, DltID , DltStatusID from 
(

	SELECT GCID, CID, DemoCID, TanganyID,	UpdateDate,	TanganyStatusID, DltID , DltStatusID
	, ROW_NUMBER () OVER (PARTITION BY CID ORDER BY UpdateDate DESC ) as RN 
	FROM   dwh_daily_process.daily_snapshot.UserApiDB_Customer_CustomerIdentification
	
)c where RN=1 and DltID is not null;

--IF NULL IS NOT NULL DROP TABLE #DLT
--CREATE TABLE #DLT
--    
--as 
--select * from 
--(
--select fsc.GCID
--	 , fsc.RealCID
--	 , fsc.DemoCID
--	 , fsc.CustomerChangeTypeID
--	 , fsc.CurentValue
--	 , fsc.PreviousValue
--	 , fsc.CountryID
--	 , fsc.LabelID
--	 , fsc.LanguageID
--	 , fsc.VerificationLevelID
--	 , fsc.DocsOK
--	 , fsc.PlayerStatusID
--	 , fsc.Bankruptcy
--	 , fsc.RiskStatusID
--	 , fsc.RiskClassificationID
--	 , fsc.CommunicationLanguageID
--	 , fsc.PremiumAccount
--	 , fsc.Evangelist
--	 , fsc.GuruStatusID
--	 , fsc.UpdateDate
--	 , fsc.RegulationID
--	 , fsc.AccountStatusID
--	 , fsc.AccountManagerID
--	 , fsc.PlayerLevelID
--	 , fsc.AccountTypeID
--	 , fsc.DateRangeID
--	 , fsc.IsDepositor
--	 , fsc.PendingClosureStatusID
--	 , fsc.DocumentStatusID
--	 , fsc.SuitabilityTestStatusID
--	 , fsc.MifidCategorizationID
--	 , CAST(fsc.IsEmailVerified AS INT)
--	 , fsc.IsValidCustomer
--	 , fsc.DesignatedRegulationID
--	 , fsc.EvMatchStatus
--	 , fsc.RegionID
--	 , fsc.PlayerStatusReasonID
--	 , fsc.IsCreditReportValidCB
--	 , fsc.AffiliateID
--	 , fsc.Email
--	 , fsc.City
--	 , fsc.Address
--	 , fsc.Zip
--	 , fsc.PhoneNumber
--	 , fsc.IsPhoneVerified
--	 , fsc.PhoneVerificationDateID
--	 , fsc.PlayerStatusSubReasonID
--	 , fsc.WeekendFeePrecentage
--	 , dlt.DltStatusID
--	 , dlt.DltID
--, ROW_NUMBER() over (partition by CID order BY DateRangeID DESC) as RN
--from dwh_daily_process.migration_tables.Fact_SnapshotCustomer fsc 
--join dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification_DLT dlt
--on fsc.RealCID = dlt.CID
--) a
--where RN=1 


/**Merge two tables together where updates occurred on both tables**/
--Insert into #DailyCustomerSnapshot where there are updates on both tables, therefore we have all of the required fields.

----DROP TABLE #DailyCustomerSnapshot
--DECLARE @dateID INT = 20241009
DROP TABLE IF EXISTS TEMP_TABLE_DailyCustomerSnapshot;
CREATE OR REPLACE TABLE TEMP_TABLE_DailyCustomerSnapshot (CID INT
, GCID INT
, CountryID INT
, LabelID INT
, LanguageID INT
, PlayerStatusID INT
, CommunicationLanguageID INT
, AccountStatusID INT
, PlayerLevelID INT
, VerificationLevelID INT
, RiskStatusID INT
, RiskClassificationID INT
, RegulationID TINYINT 
, ManagerID INT
, AccountTypeID INT
, GuruStatusID SMALLINT 
, IsDepositor BOOLEAN 
, PendingClosureStatusID TINYINT 
, DocumentStatusID INT 
, SuitabilityTestStatusID INT
, MifidCategorizationID INT
, IsEmailVerified INT
, DesignatedRegulationID INT
, EvMatchStatus INT
, RegionID INT
, PlayerStatusReasonID INT
, IsValidCustomer INT
, IsCreditReportValidCB INT
, Email STRING
, City STRING
, Address STRING
, Zip STRING
, AffiliateID int
, PhoneNumber STRING
, IsPhoneVerified BOOLEAN
, PhoneVerificationDateID STRING
, PlayerStatusSubReasonID int
, WeekendFeePrecentage int
, DltStatusID int
, DltID STRING
, EquiLendID STRING
, StocksLendingStatusID int
) USING DELTA


;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
INSERT INTO TEMP_TABLE_DailyCustomerSnapshot
SELECT DISTINCT 
	   coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID, PVD.CID,FSC.RealCID) AS CID
	 , coalesce(TEMP_TABLE_CCTemp.GCID, FSC.GCID,iden.GCID,0) AS GCID
	 , coalesce(TEMP_TABLE_CCTemp.CountryID, FSC.CountryID, 0) AS CountryID
	 , coalesce(TEMP_TABLE_CCTemp.LabelID, FSC.LabelID, 0) AS LabelID
	 , coalesce(TEMP_TABLE_CCTemp.LanguageID, FSC.LanguageID,0) AS LanguageID
	 , coalesce(TEMP_TABLE_CCTemp.PlayerStatusID, FSC.PlayerStatusID,0) AS PlayerStatusID
	 , coalesce(TEMP_TABLE_CCTemp.CommunicationLanguageID, FSC.CommunicationLanguageID,0) AS CommunicationLanguageID
	 , coalesce(TEMP_TABLE_CCTemp.AccountStatusID, FSC.AccountStatusID,0) AS AccountStatusID
	 , coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, FSC.PlayerLevelID,0) AS PlayerLevelID
	 , coalesce(TEMP_TABLE_BCTemp.VerificationLevelID, FSC.VerificationLevelID,0) AS VerificationLevelID
	 , coalesce(TEMP_TABLE_BCTemp.RiskStatusID, FSC.RiskStatusID,0) AS RiskStatusID
	 , coalesce(TEMP_TABLE_BCTemp.RiskClassificationID, FSC.RiskClassificationID,0) AS RiskClassificationID
	 , coalesce(TEMP_TABLE_BCTemp.RegulationID, FSC.RegulationID, TEMP_TABLE_BCTemp.RegulationIDBackup,0) AS RegulationID --If FromRegulationID exists in RegulationChangeLog take it, else take it from Snapshot, else take it from History.BackOffice customer (that means that it's a new customer). We shouldn't take it from BOCustomer right away b/c the regulation might have changed during the day but will be in effect only on end of day.
	 , coalesce(TEMP_TABLE_BCTemp.ManagerID, FSC.AccountManagerID,0) AS AccountManagerID --AccountManagerID
	 , coalesce(TEMP_TABLE_BCTemp.AccountTypeID, FSC.AccountTypeID,0) AS AccountTypeID --Employee = 7
	 , coalesce(TEMP_TABLE_BCTemp.GuruStatusID, FSC.GuruStatusID,0) AS GuruStatusID
	 , coalesce(TEMP_TABLE_DepositorChanges.IsDepositor, FSC.IsDepositor,0) AS IsDepositor
	 , coalesce(TEMP_TABLE_CCTemp.PendingClosureStatusID, FSC.PendingClosureStatusID,0) AS PendingClosureStatusID
	 , coalesce(TEMP_TABLE_BCTemp.DocumentStatusID, FSC.DocumentStatusID,0) AS DocumentStatusID
	 , coalesce(TEMP_TABLE_BCTemp.SuitabilityTestStatusID, FSC.SuitabilityTestStatusID,0) AS SuitabilityTestStatusID
	 , coalesce(TEMP_TABLE_BCTemp.MifidCategorizationID, FSC.MifidCategorizationID,0) AS MifidCategorizationID
	 , coalesce(CAST(TEMP_TABLE_CCTemp.IsEmailVerified AS INT), CAST(FSC.IsEmailVerified AS INT),0) AS IsEmailVerified
	 , coalesce(TEMP_TABLE_BCTemp.DesignatedRegulationID, FSC.DesignatedRegulationID,0) AS DesignatedRegulationID
	 , coalesce(TEMP_TABLE_BCTemp.EvMatchStatus, FSC.EvMatchStatus,0) AS EvMatchStatus
	 , coalesce(TEMP_TABLE_CCTemp.RegionID, FSC.RegionID,0) AS RegionID
     , coalesce(TEMP_TABLE_CCTemp.PlayerStatusReasonID, FSC.PlayerStatusReasonID,0) AS PlayerStatusReasonID
	  , case when V_date<='20200314'
			then
			case when 
			coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, FSC.PlayerLevelID,0) <> 4 And 
			coalesce(TEMP_TABLE_CCTemp.LabelID, FSC.LabelID,0) <> 30 And 
			coalesce(TEMP_TABLE_CCTemp.CountryID, FSC.CountryID,0) <> 250 and 
			coalesce(TEMP_TABLE_BCTemp.AccountTypeID, FSC.AccountTypeID,0) <> 9 then 1 else 0 end
			ELSE
			case when 
			coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, FSC.PlayerLevelID,0) <> 4 
			And coalesce(TEMP_TABLE_CCTemp.LabelID, FSC.LabelID,0) NOT IN (30, 26) 
			And coalesce(TEMP_TABLE_CCTemp.CountryID, FSC.CountryID,0) <> 250 
			then 1 else 0 end  
		end as IsValidCustomer
	  , case when V_date<='20200314'
			then
			case when (NOT (coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, FSC.PlayerLevelID,0) = 4 
			AND coalesce(TEMP_TABLE_BCTemp.AccountTypeID, FSC.AccountTypeID,0) <> 2) 
					AND coalesce(TEMP_TABLE_CCTemp.LabelID, FSC.LabelID,0) NOT IN ( 26,30) ) then 1 else 0 
					end
			ELSE
			case when (NOT (coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, FSC.PlayerLevelID,0) = 4 
			AND coalesce(TEMP_TABLE_BCTemp.AccountTypeID, FSC.AccountTypeID,0) <> 2) 
							AND coalesce(TEMP_TABLE_CCTemp.LabelID, FSC.LabelID,0) NOT IN ( 26,30) 
							AND NOT (coalesce(TEMP_TABLE_CCTemp.CountryID, FSC.CountryID,0) = 250 
							and coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID,iden.CID) NOT IN (3400616,10526243))) -- ask Guy
							
							then 1 else 0 end  

		end as IsCreditReportValidCB
		, coalesce(TEMP_TABLE_CCTemp.Email, FSC.Email, '') AS Email
		, coalesce(TEMP_TABLE_CCTemp.City, FSC.City,'') AS City
		, coalesce(TEMP_TABLE_CCTemp.Address, FSC.Address,'') AS Address
		, coalesce(TEMP_TABLE_CCTemp.Zip, FSC.Zip,'') AS Zip
		, coalesce(TEMP_TABLE_CCTemp.AffiliateID, FSC.AffiliateID,0) AS AffiliateID
		, coalesce(PVD.PhoneNumber, FSC.PhoneNumber,'') AS PhoneNumber
		, coalesce(PVD.IsPhoneVerified, FSC.IsPhoneVerified,0) AS IsPhoneVerified
		, coalesce(PVD.PhoneVerificationDateID, FSC.PhoneVerificationDateID,'') AS PhoneVerificationDateID
		, coalesce(TEMP_TABLE_CCTemp.PlayerStatusSubReasonID, FSC.PlayerStatusSubReasonID,0) AS PlayerStatusSubReasonID
		, coalesce(TEMP_TABLE_CCTemp.WeekendFeePrecentage, FSC.WeekendFeePrecentage) AS WeekendFeePrecentage
		, coalesce(iden.DltStatusID,FSC.DltStatusID,0) as DltStatusID
		, coalesce(iden.DltID,FSC.DltID,null) as DltID
		, coalesce(STL.EquiLendID,FSC.EquiLendID,null) as EquiLendID
		, coalesce(STL.StocksLendingStatusID,FSC.StocksLendingStatusID,null) as StocksLendingStatusID
		FROM TEMP_TABLE_CCTemp
	FULL JOIN TEMP_TABLE_BCTemp
		ON TEMP_TABLE_CCTemp.CID = TEMP_TABLE_BCTemp.CID
	FULL JOIN TEMP_TABLE_DepositorChanges
		ON COALESCE(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID) = TEMP_TABLE_DepositorChanges.CID
	FULL JOIN TEMP_TABLE_PhoneVerificationDetails PVD
		ON coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID) = PVD.CID
	FULL join dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification_DLT iden
		ON iden.CID=coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID, PVD.CID)
    FULL JOIN dwh_daily_process.migration_tables.Ext_FSC_StocksLending STL
		ON STL.CID=coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID, PVD.CID, iden.CID, STL.CID)
	LEFT JOIN dwh_daily_process.migration_tables.Fact_SnapshotCustomer FSC  -- Regular left join to get missing data from SnapshotCustomer
		ON (FSC.RealCID = coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, TEMP_TABLE_DepositorChanges.CID, PVD.CID, iden.CID, STL.CID)) AND CAST(left(CAST(FSC.DateRangeID AS STRING), 4) + right(CAST(FSC.DateRangeID AS STRING), 4) AS TIMESTAMP) = V_maxentrydate
		;

-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP TABLE IF EXISTS TEMP_TABLE_UpdatedRanges;
CREATE OR REPLACE TABLE TEMP_TABLE_UpdatedRanges (DateRangeID bigint NOT NULL) USING DELTA;

--DROP TABLE #outputdata
DROP TABLE IF EXISTS TEMP_TABLE_outputdata;
CREATE OR REPLACE TABLE TEMP_TABLE_outputdata (Action STRING NOT NULL,
 CID int NOT NULL,
 DateRangeID bigint NOT NULL) USING DELTA;


 --DECLARE @date AS DATE = '2025-05-05'
IF  DATEADD(YEAR, CAST(DATEDIFF(0, current_timestamp()) / 365 AS INT), 0) =  V_date
THEN
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotCustomer 
(RealCID
								   , GCID
								   , DateRangeID
								   , CountryID
								   , LabelID
								   , LanguageID
								   , VerificationLevelID
								   , PlayerStatusID
								   , RiskStatusID
								   , RiskClassificationID
								   , CommunicationLanguageID
								   , RegulationID
								   , AccountStatusID
								   , AccountManagerID
								   , PlayerLevelID
								   , AccountTypeID
								   , GuruStatusID
								   , IsDepositor
								   , PendingClosureStatusID
								   , DocumentStatusID 
								   , SuitabilityTestStatusID
								   , MifidCategorizationID
								   , IsEmailVerified
								   , IsValidCustomer
								   , IsCreditReportValidCB
								   , DesignatedRegulationID
								   , EvMatchStatus
								   , RegionID
                                   , PlayerStatusReasonID
								   , UpdateDate
								   , Email
								   , City 
								   , Address 
								   , Zip 
								   , AffiliateID
								   , PhoneNumber
								   , IsPhoneVerified
								   , PhoneVerificationDateID
								   , PlayerStatusSubReasonID
								   , WeekendFeePrecentage
								   , DltStatusID
								   , DltID
								   , EquiLendID
								   , StocksLendingStatusID
								   )
--OUTPUT inserted.DateRangeID into #UpdatedRanges
SELECT b.CID
	 , b.GCID
	 , CAST(date_format(V_date, 'yyyyMMdd') + right(date_format(V_largedate, 'yyyyMMdd'), 4) AS BIGINT)
	 , b.CountryID
	 , b.LabelID
	 , b.LanguageID
	 , b.VerificationLevelID
	 , b.PlayerStatusID
	 , b.RiskStatusID
	 , b.RiskClassificationID
	 , b.CommunicationLanguageID
	 , b.RegulationID
	 , b.AccountStatusID
	 , b.ManagerID
	 , b.PlayerLevelID
	 , b.AccountTypeID
	 , b.GuruStatusID
	 , b.IsDepositor
	 , b.PendingClosureStatusID
	 , b.DocumentStatusID 
	 , b.SuitabilityTestStatusID
	 , b.MifidCategorizationID
	 , CAST(b.IsEmailVerified AS INT)
	 , b.IsValidCustomer
	 , b.IsCreditReportValidCB

	 --, case when PlayerLevelID <> 4 
		--					And LabelID NOT IN (30, 26) 
		--					And CountryID <> 250 
		--					then 1 else 0 end  as IsValidCustomer
	 --, case when 
		--	b.PlayerLevelID <> 4 And 
		--	b.LabelID <> 30 And 
		--	b.CountryID <> 250 and 
		--	b.AccountTypeID <> 9 then 1 else 0 end as IsValidCustomer
	 --, case when (NOT (PlayerLevelID = 4 AND AccountTypeID <> 2) 
		--			AND LabelID NOT IN ( 26,30) ) then 1 else 0 
		--			end as IsCreditReportValidCB
	 --, case when (NOT (PlayerLevelID = 4 AND AccountTypeID <> 2) 
		--					AND LabelID NOT IN ( 26,30) 
		--					AND NOT (CountryID = 250 and b.CID NOT IN (3400616,10526243))) 
		--					then 1 else 0 end as IsCreditReportValidCB 
	 , DesignatedRegulationID
	 , EvMatchStatus
	 , RegionID
     , PlayerStatusReasonID
	 , current_timestamp()
	 , Email
	 , City 
	 , Address 
	 , Zip 
	 , AffiliateID
	 , PhoneNumber
	 , IsPhoneVerified
	 , PhoneVerificationDateID
	 , PlayerStatusSubReasonID
	 , WeekendFeePrecentage
	 , DltStatusID
	 , DltID
	 , EquiLendID
     , StocksLendingStatusID
FROM TEMP_TABLE_DailyCustomerSnapshot AS b
WHERE CID IN (
			  SELECT CID
			  FROM TEMP_TABLE_NewCIDs
			 );


--OUTPUT inserted.DateRangeID into #UpdatedRanges;

--OUTPUT
--$action,
--inserted.DateRangeID
--INTO #UpdatedRanges;

--declare @rowcount_insert as int
--set @rowcount_insert = (SELECT count(*) FROM #outputdata a WHERE Action = 'INSERT')


	--	
	--SELECT @row_count = ISNULL(row_count,0)
	-- FROM sys.dm_pdw_request_steps s, sys.dm_pdw_exec_requests r
	--Where r.request_id = s.request_id 
	--and row_count > -1
	--and r.[label] = '#DailyCustomerSnapshot'
	--ORDER by r.[end_time] desc;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END IF; 

/**Update date + Insert, for existing CIDs**/
IF  DATEADD(YEAR, CAST(DATEDIFF(0, current_timestamp()) / 365 AS INT), 0) <>  V_date
THEN
--EXEC SP_Log_Full 'Fact_SnapshotCustomer','Update Old Customer',@dateID,1,0

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotCustomer AS a
USING TEMP_TABLE_DailyCustomerSnapshot AS b   
ON a.RealCID=b.CID
--Close the date for rows which have an update (later we open a new one with an "open" date):
WHEN MATCHED AND 
(
(COALESCE(CAST(a.CountryID AS int), -1) <> COALESCE(CAST(b.CountryID AS int), -1)) or
(COALESCE(CAST(a.LabelID AS int), -1) <> COALESCE(CAST(b.LabelID AS int), -1)) or
(COALESCE(CAST(a.LanguageID AS int), -1) <> COALESCE(CAST(b.LanguageID AS int), -1)) or
(COALESCE(CAST(a.PlayerStatusID AS int), -1) <> COALESCE(CAST(b.PlayerStatusID AS int), -1)) or
(COALESCE(CAST(a.CommunicationLanguageID AS int), -1) <> COALESCE(CAST(b.CommunicationLanguageID AS int), -1)) or
(COALESCE(CAST(a.PlayerLevelID AS int), -1) <> COALESCE(CAST(b.PlayerLevelID AS int), -1)) or
(COALESCE(CAST(a.VerificationLevelID AS int), -1) <> COALESCE(CAST(b.VerificationLevelID AS int), -1)) or
(COALESCE(CAST(a.RiskStatusID AS int), -1) <> COALESCE(CAST(b.RiskStatusID AS int), -1)) or
(COALESCE(CAST(a.RiskClassificationID AS int), -1) <> COALESCE(CAST(b.RiskClassificationID AS int), -1)) or
(COALESCE(CAST(a.RegulationID AS int), 0) <> COALESCE(CAST(b.RegulationID AS int), 0)) or
(COALESCE(CAST(a.AccountManagerID AS int), -1) <> COALESCE(CAST(b.ManagerID AS int), -1)) or
(COALESCE(CAST(a.AccountTypeID AS int), -1) <> COALESCE(CAST(b.AccountTypeID AS int), -1)) or
(COALESCE(CAST(a.GuruStatusID AS int), -1) <> COALESCE(CAST(b.GuruStatusID AS int), -1)) or
(COALESCE(CAST(a.IsDepositor AS int), -1) <> COALESCE(CAST(b.IsDepositor AS int), -1)) or
(COALESCE(CAST(a.PendingClosureStatusID AS int), -1) <> COALESCE(CAST(b.PendingClosureStatusID AS int), -1)) or
(COALESCE(CAST(a.DocumentStatusID AS int), -1) <> COALESCE(CAST(b.DocumentStatusID AS int), -1)) or
(COALESCE(CAST(a.SuitabilityTestStatusID AS int), -1) <> COALESCE(CAST(b.SuitabilityTestStatusID AS int), -1)) or
(COALESCE(CAST(a.MifidCategorizationID AS int), -1) <> COALESCE(CAST(b.MifidCategorizationID AS int), -1)) or 
(COALESCE(CAST(a.IsEmailVerified AS int), -1) <> COALESCE(CAST(b.IsEmailVerified AS int), -1)) or
(COALESCE(CAST(a.DesignatedRegulationID AS int), -1) <> COALESCE(CAST(b.DesignatedRegulationID AS int), -1)) or
(COALESCE(CAST(a.EvMatchStatus AS int), -1) <> COALESCE(CAST(b.EvMatchStatus AS int), -1)) or
(COALESCE(CAST(a.RegionID AS int), -1) <> COALESCE(CAST(b.RegionID AS int), -1)) OR
(COALESCE(CAST(a.PlayerStatusReasonID AS int), -1) <> COALESCE(CAST(b.PlayerStatusReasonID AS int), -1)) OR 
(COALESCE(CAST(a.IsValidCustomer AS int), -1) <> COALESCE(CAST(b.IsValidCustomer AS int), -1)) OR 
(COALESCE(CAST(a.IsCreditReportValidCB AS int), -1) <> COALESCE(CAST(b.IsCreditReportValidCB AS int), -1)) OR
(COALESCE(CAST(a.Email AS STRING), '') <> COALESCE(CAST(b.Email AS STRING), '')) OR
(COALESCE(CAST(a.City AS STRING), '') <> COALESCE(CAST(b.City AS STRING), '')) OR
(COALESCE(CAST(a.Address AS STRING), '') <> COALESCE(CAST(b.Address AS STRING), '')) OR
(COALESCE(CAST(a.Zip AS STRING), '') <> COALESCE(CAST(b.Zip AS STRING), '')) OR 
(COALESCE(CAST(a.AffiliateID AS int), -1) <> COALESCE(CAST(b.AffiliateID AS int), -1)) OR
(COALESCE(CAST(a.PhoneNumber AS STRING), '') <> COALESCE(CAST(b.PhoneNumber AS STRING), '')) OR
(COALESCE(CAST(a.IsPhoneVerified AS BOOLEAN), -1) <> COALESCE(CAST(b.IsPhoneVerified AS BOOLEAN), -1)) OR
(COALESCE(CAST(a.PhoneVerificationDateID AS STRING), '') <> COALESCE(CAST(b.PhoneVerificationDateID AS STRING), '')) OR
(COALESCE(CAST(a.PlayerStatusSubReasonID AS int), 0) <> COALESCE(CAST(b.PlayerStatusSubReasonID AS int), 0)) OR
(COALESCE(CAST(a.WeekendFeePrecentage AS int), -1) <> COALESCE(CAST(b.WeekendFeePrecentage AS int), -1)) OR
(COALESCE(CAST(a.DltStatusID AS int), -1) <> COALESCE(CAST(b.DltStatusID AS int), -1)) OR
(COALESCE(CAST(a.EquiLendID AS STRING), '') <> COALESCE(CAST(b.EquiLendID AS STRING), '')) OR
(COALESCE(CAST(a.StocksLendingStatusID AS int), -1) <> COALESCE(CAST(b.StocksLendingStatusID AS int), -1))
)
AND CAST(left(CAST(DateRangeID AS STRING),4)+right(CAST(DateRangeID AS STRING),4) AS TIMESTAMP)=V_maxentrydate THEN UPDATE SET DateRangeID=CAST(left(CAST(DateRangeID AS STRING),8)+right(date_format(V_daybefore, 'yyyyMMdd'),4) AS bigint) , UpdateDate = current_timestamp()
WHEN NOT MATCHED 
THEN INSERT (RealCID
,GCID
,DateRangeID
,CountryID
,LabelID
,LanguageID
,VerificationLevelID
,PlayerStatusID
,RiskStatusID
,RiskClassificationID
,CommunicationLanguageID
,RegulationID
,AccountStatusID
,AccountManagerID
,PlayerLevelID
,AccountTypeID
,GuruStatusID
,IsDepositor
,PendingClosureStatusID
,DocumentStatusID 
,SuitabilityTestStatusID
,MifidCategorizationID
,IsEmailVerified
,IsValidCustomer
,IsCreditReportValidCB
,DesignatedRegulationID
,EvMatchStatus
,RegionID
,PlayerStatusReasonID
,UpdateDate
,Email
,City 
,Address 
,Zip 
,AffiliateID
,PhoneNumber
,IsPhoneVerified
,PhoneVerificationDateID
,PlayerStatusSubReasonID
,WeekendFeePrecentage
,DltStatusID
,DltID
,EquiLendID
,StocksLendingStatusID
)
VALUES (
b.CID
,b.GCID
,CAST(date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4) AS bigint)
,b.CountryID
,b.LabelID
,b.LanguageID
,b.VerificationLevelID
,b.PlayerStatusID
,b.RiskStatusID
,b.RiskClassificationID
,b.CommunicationLanguageID
,b.RegulationID
,b.AccountStatusID
,b.ManagerID
,b.PlayerLevelID
,b.AccountTypeID
,b.GuruStatusID
,b.IsDepositor
,b.PendingClosureStatusID
,b.DocumentStatusID 
,b.SuitabilityTestStatusID
,b.MifidCategorizationID
,CAST(b.IsEmailVerified AS INT)
,b.IsValidCustomer
,b.IsCreditReportValidCB
,b.DesignatedRegulationID
,b.EvMatchStatus
,b.RegionID
,b.PlayerStatusReasonID
,current_timestamp()
,b.Email
,b.City 
,b.Address 
,b.Zip 
,b.AffiliateID
,b.PhoneNumber
,b.IsPhoneVerified
,b.PhoneVerificationDateID
,b.PlayerStatusSubReasonID
,b.WeekendFeePrecentage
,b.DltStatusID
,b.DltID
,b.EquiLendID
,b.StocksLendingStatusID
);
	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
--OUTPUT
--$action,
--inserted.RealCID,
--inserted.DateRangeID
--INTO #outputdata;

INSERT INTO TEMP_TABLE_outputdata
SELECT 'UPDATE' AS action,
RealCID,
DateRangeID 
FROM dwh_daily_process.migration_tables.Fact_SnapshotCustomer 
WHERE DateRangeID=CAST(left(CAST(DateRangeID AS STRING),8)+right(date_format(V_daybefore, 'yyyyMMdd'),4) AS bigint)
AND left(DateRangeID,4) = YEAR(V_date) --- Update from 2022.04.03
;
--UPDATE SET DateRangeID=convert(bigint,left(convert (Varchar(20),DateRangeID),8)+right(convert (Varchar,@daybefore,112),4))


--declare @rowcount_insert as int
--set @rowcount_insert = (SELECT count(*) FROM #outputdata a WHERE Action = 'INSERT')

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotCustomer
	(RealCID
   , GCID
   , DateRangeID
   , CountryID
   , LabelID
   , LanguageID
   , VerificationLevelID
   , PlayerStatusID
   , RiskStatusID
   , RiskClassificationID
   , CommunicationLanguageID
   , RegulationID
   , AccountStatusID
   , AccountManagerID
   , PlayerLevelID
   , AccountTypeID
   , GuruStatusID
   , IsDepositor
   , PendingClosureStatusID
   , DocumentStatusID 
   , SuitabilityTestStatusID
   , MifidCategorizationID
   , IsEmailVerified
   , IsValidCustomer
   , IsCreditReportValidCB
   , DesignatedRegulationID
   , EvMatchStatus
   , RegionID
   , PlayerStatusReasonID
   , UpdateDate
   , Email
   , City 
   , Address 
   , Zip    
   , AffiliateID
   , PhoneNumber
   , IsPhoneVerified
   , PhoneVerificationDateID
   , PlayerStatusSubReasonID
   , WeekendFeePrecentage
   , DltStatusID
   , DltID
   , EquiLendID
   , StocksLendingStatusID
   )
SELECT b.CID
	 , b.GCID
	 , CAST(date_format(V_date, 'yyyyMMdd') + right(date_format(V_largedate, 'yyyyMMdd'), 4) AS BIGINT)
	 , b.CountryID
	 , b.LabelID
	 , b.LanguageID
	 , b.VerificationLevelID
	 , b.PlayerStatusID
	 , b.RiskStatusID
	 , b.RiskClassificationID
	 , b.CommunicationLanguageID
	 , b.RegulationID
	 , b.AccountStatusID
	 , b.ManagerID
	 , b.PlayerLevelID
	 , b.AccountTypeID
	 , b.GuruStatusID
	 , b.IsDepositor
	 , b.PendingClosureStatusID
	 , b.DocumentStatusID 
	 , b.SuitabilityTestStatusID
	 , b.MifidCategorizationID
	 , CAST(b.IsEmailVerified AS INT)
	 , b.IsValidCustomer
	 , b.IsCreditReportValidCB
	 , b.DesignatedRegulationID
	 , b.EvMatchStatus
	 , RegionID
     , PlayerStatusReasonID
	 , current_timestamp()
	 , Email
	 , City 
	 , Address 
	 , Zip 
	 , AffiliateID
	 , PhoneNumber
	 , IsPhoneVerified
	 , PhoneVerificationDateID
	 , PlayerStatusSubReasonID
	 , WeekendFeePrecentage
	 ,b.DltStatusID
	 ,b.DltID
	 ,b.EquiLendID
     ,b.StocksLendingStatusID
FROM TEMP_TABLE_DailyCustomerSnapshot b
WHERE EXISTS (
			  SELECT 1
			  FROM TEMP_TABLE_outputdata a
			  WHERE Action = 'UPDATE'
				  AND a.CID = b.CID
			 );
	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END IF;

/****************************************************************Insert new DateRange Keys*********************************************************************************/
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks) INSERT INTO dwh_daily_process.migration_tables.Dim_Range (DateRangeID , FromDateID , ToDateID , UpdateDate) SELECT DISTINCT DateRangeID , CAST(left(CAST(DateRangeID AS STRING), 8) AS BIGINT) , CAST(left(CAST(DateRangeID AS STRING), 4) + right(CAST(DateRangeID AS STRING), 4) AS BIGINT) , current_timestamp() FROM TEMP_TABLE_outputdata WHERE Action = 'UPDATE' AND DateRangeID NOT IN (select DateRangeID FROM dwh_daily_process.migration_tables.Dim_Range)

INSERT INTO dwh_daily_process.migration_tables.Dim_Range 
(DateRangeID
					 , FromDateID
					 , ToDateID
					 , UpdateDate)
SELECT CAST(date_format(V_date, 'yyyyMMdd') + right(date_format(V_largedate, 'yyyyMMdd'), 4) AS BIGINT)
	 , CAST((date_format(V_date, 'yyyyMMdd')) AS INT)
	 , CAST((date_format(V_largedate, 'yyyyMMdd')) AS INT)
	 , current_timestamp()
	 WHERE CAST(date_format(V_date, 'yyyyMMdd') + right(date_format(V_largedate, 'yyyyMMdd'), 4) AS BIGINT) NOT IN (select DateRangeID FROM dwh_daily_process.migration_tables.Dim_Range);



--Note: Here we insert the new DateRange keys that were created today.
INSERT INTO dwh_daily_process.migration_tables.Dim_Range 
(DateRangeID
					 , FromDateID
					 , ToDateID
					 , UpdateDate)
SELECT DISTINCT DateRangeID
			  , CAST(left(CAST(DateRangeID AS STRING), 8) AS BIGINT)
			  , CAST(left(CAST(DateRangeID AS STRING), 4) + right(CAST(DateRangeID AS STRING), 4) AS BIGINT)
			  , current_timestamp()
FROM TEMP_TABLE_UpdatedRanges --Date ranges that were closed and inserted today
WHERE  DateRangeID NOT IN (
							SELECT DateRangeID
							FROM dwh_daily_process.migration_tables.Dim_Range
						   ) --where they don't already exist
		;

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_DelUserName;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_DelUserName AS
select  UserName, CID, Email, City, Address,  Zip

from  dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_Customer
where  UserName like '%DelUserName%'
;
MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotCustomer a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Fact_SnapshotCustomer a
INNER JOIN TEMP_TABLE_DelUserName b on a.RealCID = b.CID 

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY 1) = 1
)
ON a.RealCID = a_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
Email = b.Email ,
City = b.City ,
Address = b.Address ,
Zip = b.Zip ,
PhoneNumber = 'DelPhoneNumber_' || SUBSTRING ( b.UserName , 13 , LENGTH( b.UserName ) );
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_BCTemp;
DROP VIEW IF EXISTS TEMP_TABLE_BCTempNoReg;
DROP VIEW IF EXISTS TEMP_TABLE_CCTemp;
DROP TABLE IF EXISTS TEMP_TABLE_DailyCustomerSnapshot;
DROP VIEW IF EXISTS TEMP_TABLE_DelUserName;
DROP VIEW IF EXISTS TEMP_TABLE_DepositorChanges;
DROP VIEW IF EXISTS TEMP_TABLE_ExistCIDs;
DROP VIEW IF EXISTS TEMP_TABLE_NewCIDs;
DROP VIEW IF EXISTS TEMP_TABLE_PhoneVerificationDetails;
DROP VIEW IF EXISTS TEMP_TABLE_RegulationChanges;
DROP TABLE IF EXISTS TEMP_TABLE_UpdatedRanges;
DROP TABLE IF EXISTS TEMP_TABLE_outputdata;
END