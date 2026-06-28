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
----Declare @date as DATETIME

--SET @date = '2021-01-01 00:00:00'
--EXEC [DWH_dbo].[SP_Fact_SnapshotCustomerCloseYear] @date
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-03-11
Description: [SP_Fact_SnapshotCustomerCloseYear]
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
 2020-02-23     Boris        Add column  IsCreditReportValidCB
 2020-02-15     Boris		 Change case for IsCreditReportValidCB + IsValidCustomer  from 2020.03.15
 2022-12-28		Inbal		 Add columns: PhoneNumber, IsPhoneVerified, PhoneVerificationDateID and PlayerStatusSubReasonID
 2022-02-19		Inbal		 Add GDPR in order to update PhoneNumber
 2024-04-01		Inbal		 Add WeekendFeePrecentage to [DWH_dbo].Ext_FSC_Real_Customer_CustomerCloseYear
 2025-03-18     Adi Ferber   Replace Ext_FSC_PhoneVerificationDetailsCloseYear with Ext_FSC_PhoneCustomerCloseYear - new DB and new table with all the phone details 
 2025-10-29     Daniel Kaplan Add new DLT, FTD fields 
*********************************************************************************************/
-- DECLARE @date as [Date] = '2025-01-01'

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
					);
SELECT  V_date

;
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

SELECT coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, PVD.CID ) AS CID
	 , coalesce(TEMP_TABLE_CCTemp.GCID,0) AS GCID
	 , CAST(CAST(year(V_date) AS STRING) || '01011231' AS BIGINT) AS DateRangeID
	 , coalesce(TEMP_TABLE_CCTemp.CountryID,0) AS CountryID
	 , coalesce(TEMP_TABLE_CCTemp.LabelID,0) AS LabelID
	 , coalesce(TEMP_TABLE_CCTemp.LanguageID, 0) AS LanguageID
	 , coalesce(TEMP_TABLE_BCTemp.VerificationLevelID,0) AS VerificationLevelID
	 , coalesce(TEMP_TABLE_CCTemp.PlayerStatusID,0) AS PlayerStatusID
	 , coalesce(TEMP_TABLE_BCTemp.RiskStatusID, 0) AS RiskStatusID
	 , coalesce(TEMP_TABLE_BCTemp.RiskClassificationID, 0) AS RiskClassificationID
	 , coalesce(TEMP_TABLE_CCTemp.CommunicationLanguageID, 0) AS CommunicationLanguageID
	 , coalesce(TEMP_TABLE_BCTemp.RegulationID,0) AS RegulationID
	 , coalesce(TEMP_TABLE_CCTemp.AccountStatusID, 0) AS AccountStatusID
	 , coalesce(TEMP_TABLE_BCTemp.AccountManagerID, 0) AS AccountManagerID
	 , coalesce(TEMP_TABLE_CCTemp.PlayerLevelID, 0) AS PlayerLevelID
	 , coalesce(TEMP_TABLE_BCTemp.AccountTypeID, 0) AS AccountTypeID --Employee = 7
	 , coalesce(TEMP_TABLE_BCTemp.GuruStatusID, 0) AS GuruStatusID
	 , COALESCE(CAST(TEMP_TABLE_CUS.IsDepositor AS BOOLEAN), FALSE) AS IsDepositor
	 , coalesce(TEMP_TABLE_CCTemp.PendingClosureStatusID, 0) AS PendingClosureStatusID
	 , coalesce(TEMP_TABLE_BCTemp.DocumentStatusID, 0) AS DocumentStatusID
     , coalesce(TEMP_TABLE_BCTemp.SuitabilityTestStatusID, 0) AS SuitabilityTestStatusID
     , coalesce(TEMP_TABLE_BCTemp.MifidCategorizationID, 0) AS MifidCategorizationID
	 , coalesce(CAST(TEMP_TABLE_CCTemp.IsEmailVerified AS INT), 0) AS IsEmailVerified
	 , case when V_date<='20200314'--'20200315'
			then
			case when 
			TEMP_TABLE_CCTemp.PlayerLevelID <> 4 And 
			TEMP_TABLE_CCTemp.LabelID <> 30 And 
			TEMP_TABLE_CCTemp.CountryID <> 250 and 
			TEMP_TABLE_BCTemp.AccountTypeID <> 9 then 1 else 0 end
			ELSE
			case when 
			TEMP_TABLE_CCTemp.PlayerLevelID <> 4 
			And TEMP_TABLE_CCTemp.LabelID NOT IN (30, 26) 
			And TEMP_TABLE_CCTemp.CountryID <> 250 
			then 1 else 0 end  
		end as IsValidCustomer
	  , case when V_date<='20200314'
			then
			case when (NOT (TEMP_TABLE_CCTemp.PlayerLevelID = 4 AND TEMP_TABLE_BCTemp.AccountTypeID <> 2) 
					AND TEMP_TABLE_CCTemp.LabelID NOT IN ( 26,30) ) then 1 else 0 
					end
			ELSE
			case when (NOT (TEMP_TABLE_CCTemp.PlayerLevelID = 4 AND TEMP_TABLE_BCTemp.AccountTypeID <> 2) 
							AND TEMP_TABLE_CCTemp.LabelID NOT IN ( 26,30) 
							AND NOT (TEMP_TABLE_CCTemp.CountryID = 250 and TEMP_TABLE_CCTemp.CID NOT IN (3400616,10526243))) 
							then 1 else 0 end  
		end as IsCreditReportValidCB

	 --, case when 
		--	#CCTemp.PlayerLevelID <> 4 And 
		--	#CCTemp.LabelID <> 30 And 
		--	#CCTemp.CountryID <> 250 and 
		--	#BCTemp.AccountTypeID <> 9 then 1 else 0 end as IsValidCustomer
	--, case when #CCTemp.PlayerLevelID <> 4 
	--		    And #CCTemp.LabelID NOT IN (30, 26) 
	--			And #CCTemp.CountryID <> 250 
	--			then 1 else 0 end as IsValidCustomer
	-- , case when (NOT (#CCTemp.PlayerLevelID = 4 AND #BCTemp.AccountTypeID <> 2) 
	--						AND #CCTemp.LabelID NOT IN ( 26,30) 
	--						AND NOT (#CCTemp.CountryID = 250 and #CCTemp.CID NOT IN (3400616,10526243))) 
	--						then 1 else 0 end as IsCreditReportValidCB 
 --    --, case when (NOT (#CCTemp.PlayerLevelID = 4 AND #BCTemp.AccountTypeID <> 2) 
	--				--AND #CCTemp.LabelID NOT IN ( 26,30) ) then 1 else 0 
	--				--end as IsCreditReportValidCB
     , coalesce(TEMP_TABLE_BCTemp.DesignatedRegulationID, 0) AS DesignatedRegulationID
	 , coalesce(TEMP_TABLE_BCTemp.EvMatchStatus, 0) AS EvMatchStatus
	 , coalesce(TEMP_TABLE_CCTemp.RegionID, 0) AS RegionID
     , coalesce(TEMP_TABLE_CCTemp.PlayerStatusReasonID, 0) AS PlayerStatusReasonID
	 , current_timestamp()
	 , coalesce(Email, '') as Email
	 , coalesce(City, '') as City
	 , coalesce(Address, '')  as Address
	 , coalesce(Zip , '') as Zip
	 , coalesce(AffiliateID , 0) as AffiliateID
	 , coalesce(PVD.PhoneNumber,'') AS PhoneNumber
	 , CASE WHEN PVD.PhoneVerifiedID IN (1, 2) THEN 1 ELSE 0 END AS IsPhoneVerified
	 , coalesce(PVD.PhoneVerificationDateID, '') AS PhoneVerificationDateID
	 , coalesce(TEMP_TABLE_CCTemp.PlayerStatusSubReasonID, '') AS PlayerStatusSubReasonID
	 , TEMP_TABLE_CCTemp.WeekendFeePrecentage  AS WeekendFeePrecentage
	 , coalesce(TEMP_TABLE_CUS.DltStatusID, 0) AS DltStatusID
	 , coalesce(TEMP_TABLE_CUS.DltID, '') AS DltID
	 , coalesce(TEMP_TABLE_CUS.EquiLendID, '') AS EquiLendID
	 , coalesce(TEMP_TABLE_CUS.StocksLendingStatusID, 0) AS StocksLendingStatusID
FROM dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_CustomerCloseYear TEMP_TABLE_CCTemp
	FULL JOIN dwh_daily_process.migration_tables.Ext_FSC_BackOffice_CustomerCloseYear TEMP_TABLE_BCTemp
		ON TEMP_TABLE_CCTemp.CID = TEMP_TABLE_BCTemp.CID
	--FULL JOIN [DWH_dbo].Ext_FSC_IsDepositorCloseYear  #DCTemp
	--	ON isnull(#CCTemp.CID,#BCTemp.CID) = #DCTemp.CID
	FULL JOIN dwh_daily_process.migration_tables.Ext_FSC_PhoneCustomerCloseYear PVD
		ON coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID) = PVD.CID
	FULL JOIN dwh_daily_process.migration_tables.Ext_FSC_DimCustomerCloseYear TEMP_TABLE_CUS
		ON coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID) = TEMP_TABLE_CUS.RealCID
	--    LEFT JOIN Fact_SnapshotCustomer FSC With (Nolock) -- Regular left join to get missing data from SnapshotCustomer
	--	ON (FSC.RealCID = coalesce(#CCTemp.CID, #BCTemp.CID)) AND convert(DATETIME, left(convert(VARCHAR(16), FSC.DateRangeID), 4) + right(convert(VARCHAR(16), FSC.DateRangeID), 4)) = @maxentrydate
	WHERE coalesce(TEMP_TABLE_CCTemp.CID, TEMP_TABLE_BCTemp.CID, PVD.CID,TEMP_TABLE_CUS.RealCID )  IN (
						SELECT Distinct RealCID
						FROM dwh_daily_process.migration_tables.Fact_SnapshotCustomer
						);
	--					where DateRangeID = convert(BIGINT, convert(VARCHAR(4), year(@date)) || '01011231')
	--				   ) --Do not open new rows for CIDs that have been updated today, will create double inserted rows

	-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
--------------------------GDPR

DROP VIEW IF EXISTS TEMP_TABLE_DelUserName;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_DelUserName AS
select  TEMP_TABLE_CCTemp.UserName, TEMP_TABLE_CCTemp.CID

FROM dwh_daily_process.migration_tables.Ext_FSC_Real_Customer_CustomerCloseYear TEMP_TABLE_CCTemp
	WHERE TEMP_TABLE_CCTemp.CID  IN (
						SELECT Distinct RealCID
						FROM dwh_daily_process.migration_tables.Fact_SnapshotCustomer) 
and TEMP_TABLE_CCTemp.UserName like '%DelUserName%';

--select * from  #DelUserName
MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotCustomer a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Fact_SnapshotCustomer a
INNER JOIN TEMP_TABLE_DelUserName b on a.RealCID = b.CID --END


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.RealCID ORDER BY 1) = 1
)
ON a.RealCID = a_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
PhoneNumber = 'DelPhoneNumber_' || SUBSTRING ( b.UserName , 13 , LENGTH( b.UserName ) );
SET  V_row_count = COALESCE(V_row_count, 0)
;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_DelUserName;
END