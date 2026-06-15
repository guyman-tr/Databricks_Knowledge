USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Customer_20240104(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_end DATE DEFAULT date_trunc('day', current_date());
DECLARE V_dateID INT ;

DECLARE V_rnum int ;
DECLARE V_avtar_rn INT ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Dim_Customer
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2020-02-23     Boris         Add column  CashoutFeeGroupID + IsCreditReportValidCB
2020-02-15     Boris		 Change case for IsCreditReportValidCB + IsValidCustomer from 2020.03.15
2020-12-16     Boris         Add script Update for 2FA
2021-05-09     Boris         Add POBCountryID
2022-12-12	   Eyal			 Add CIDs to IsCreditReportValidCB logic
2023-01-08	   InbalBML		 Add PhoneVerificationDetails columns
2023-03-14	   Inbal BML     Add WeekendFeePrecentage to Dim_Customer
2023-03-26	   Merav Hu      Replace Ext_Dim_Customer_History_Credit with Ext_etoro_Billing_vDeposit
2023-04-03     Nir H		 replace isnull on column RiskClassificationID  from 0 to 200
2023-11-23     Inbal BML	 Add TanganyID and TanganyStatusID cloumns to Dim_Customer
2023-11-27     Inbal BML	 Remove the update of WorldCheckID and WorldCheckResultsUpdated cloumns

*********************************************************************************************/
SET V_dateID = CAST(date_format(current_timestamp(), 'yyyyMMdd') AS int)
;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_customer;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_customer  
 AS
			SELECT	cc.GCID
				, cc.CID 
				, cc.OriginalCID
				, cc.UserName
				, cc.FirstName 
				, cc.LastName
				, cc.MiddleName
				, cc.Gender
				, cc.BirthDate
				, cc.ReferralID
				, cc.CountryID
				, cc.IP
				, cc.Phone
				, cc.Zip
				, cc.Address
				, cc.BuildingNumber
				, cc.City
				, cc.SerialID AS AffiliateID
				, cc.CampaignID
				, cc.LabelID
				, cc.LanguageID
				, cc.Email
				, cc.PlayerStatusID
				, cc.PlayerLevelID
				, cc.FunnelID
				, cc.DownloadID
				, cc.Registered
				, cc.FunnelFromID
				, cc.CommunicationLanguageID
				, cc.BannerID
				, cc.AccountStatusID
				, cc.ID
				, cc.ExternalID
				, cc.PlayerStatusReasonID
				, cc.PendingClosureStatusID
				, cc.CountryIDByIP
				, cc.SubSerialID
				, bc.VerificationLevelID
				, bc.RiskStatusID
				, bc.RiskClassificationID
				, bc.isEmployeeAccount AS EmployeeAccount
				, bc.GuruStatusID
				, bc.AccountTypeID
				, bc.RegulationID
				, bc.ManagerID AS AccountManagerID
				, bc.EvMatchStatus
				, bc.DocumentStatusID
				, bc.RegulationChangeDate
				, bc.IsCopyBlocked
				--, bc.WorldCheckID
				, bc.IsEDD
				, bc.MifidCategorizationID
				, bc.SuitabilityTestStatusID
				, CAST(cc.IsEmailVerified AS INT)
				, bc.DesignatedRegulationID
				, cc.RegionByIP_ID
				, cc.RegionID
				, COALESCE(CAST(bc.HasWallet AS INT), 0) as HasWallet
				, COALESCE(bc.PhoneVerifiedID, 0) as PhoneVerifiedID
				, CitizenshipCountryID
				, PlayerStatusSubReasonID
				, PrivacyPolicyID
				, CashoutFeeGroupID
				, case when PlayerLevelID <> 4 
							And LabelID NOT IN (30, 26) 
							And CountryID <> 250 
							then 1 else 0 end  as IsValidCustomer
				--, case when PlayerLevelID <> 4 
				--			And LabelID <> 30 
				--			And CountryID <> 250 
				--			and AccountTypeID <> 9 
				--		   then 1 else 0 end as IsValidCustomer
				, case when (NOT (PlayerLevelID = 4 AND AccountTypeID <> 2) 
							AND LabelID NOT IN ( 26,30) 
							AND NOT (CountryID = 250 and cc.CID NOT IN (3400616,10526243,10842855,11464063,21547142))) 
							then 1 else 0 end as IsCreditReportValidCB  -- from 2020.03.15  - change case
				--, case when (NOT (PlayerLevelID = 4 AND AccountTypeID <> 2) 
				--			AND LabelID NOT IN ( 26,30) ) 
				--			then 1 else 0 end as IsCreditReportValidCB
				, bc.SalesForceAccountID
				, cc.POBCountryID
				, cc.WeekendFeePrecentage
FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Customer cc
		JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_BOCustomer bc
		ON cc.CID=bc.CID

		
 

			  ;
DROP VIEW IF EXISTS TEMP_TABLE_new;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_new  
 AS

SELECT CID 
FROM TEMP_TABLE_customer a 
WHERE NOT EXISTS (SELECT NULL FROM dwh_daily_process.migration_tables.Dim_Customer WHERE RealCID = a.CID)



			  ;
DROP VIEW IF EXISTS TEMP_TABLE_update;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_update  
 AS


 SELECT a.CID
 FROM dwh_daily_process.migration_tables.Dim_Customer dc
 JOIN TEMP_TABLE_customer a on a.CID=dc.RealCID
 WHERE 	NOT (dc.UserName <=> a.UserName)                                                                 
		OR NOT (dc.FirstName <=> a.FirstName) 
		OR NOT (dc.LastName <=> a.LastName) 
		OR NOT (dc.MiddleName <=> a.MiddleName) 
		OR NOT (dc.Gender <=> a.Gender) 
		OR NOT (dc.BirthDate <=> a.BirthDate)
		OR NOT (dc.ReferralID <=> a.ReferralID)
		OR NOT (dc.CountryID <=> a.CountryID)
		OR NOT (dc.Phone <=> a.Phone) 
		OR NOT (dc.Zip <=> a.Zip) 
		OR NOT (dc.Address <=> a.Address) 
		OR NOT (dc.BuildingNumber <=> a.BuildingNumber) 
		OR NOT (dc.City <=> a.City) 
		OR NOT (dc.AffiliateID <=> a.AffiliateID)
		OR NOT (dc.CampaignID <=> a.CampaignID)
		OR NOT (dc.LabelID <=> a.LabelID)
		OR NOT (dc.LanguageID <=> a.LanguageID)
		OR NOT (dc.Email <=> a.Email) 
		OR NOT (dc.PlayerStatusID <=> a.PlayerStatusID)
		OR NOT (dc.PlayerLevelID <=> a.PlayerLevelID)
		OR NOT (dc.FunnelID <=> a.FunnelID)
		OR NOT (dc.DownloadID <=> a.DownloadID)
		OR NOT (dc.RegisteredReal <=> a.Registered)
		OR NOT (dc.FunnelFromID <=> a.FunnelFromID)
		OR NOT (dc.CommunicationLanguageID <=> a.CommunicationLanguageID)
		OR NOT (dc.BannerID <=> a.BannerID)
		OR NOT (dc.AccountStatusID <=> a.AccountStatusID)
		OR NOT (dc.PlayerStatusReasonID <=> a.PlayerStatusReasonID)
		OR NOT (dc.PendingClosureStatusID <=> a.PendingClosureStatusID)
		OR NOT (dc.CountryIDByIP <=> a.CountryIDByIP)
		OR NOT (dc.SubSerialID <=> a.SubSerialID) 
		OR NOT (dc.VerificationLevelID <=> a.VerificationLevelID)
		OR NOT (dc.RiskStatusID <=> a.RiskStatusID)
		OR COALESCE(dc.RiskClassificationID, 200) <> COALESCE(a.RiskClassificationID, 200)
		OR NOT (dc.EmployeeAccount <=> a.EmployeeAccount)
		OR NOT (dc.GuruStatusID <=> a.GuruStatusID)
		OR NOT (dc.AccountTypeID <=> a.AccountTypeID)
		OR NOT (dc.RegulationID <=> a.RegulationID)
		OR NOT (dc.AccountManagerID <=> a.AccountManagerID)
		OR NOT (dc.EvMatchStatus <=> a.EvMatchStatus)
		OR NOT (dc.DocumentStatusID <=> a.DocumentStatusID)
		OR NOT (dc.RegulationChangeDate <=> a.RegulationChangeDate)
		OR NOT (dc.IsCopyBlocked <=> a.IsCopyBlocked)
		--OR ISNULL(dc.WorldCheckID,0) <> ISNULL(a.WorldCheckID,0)
		OR NOT (dc.IsEDD <=> a.IsEDD)
		OR NOT (dc.SuitabilityTestStatusID <=> a.SuitabilityTestStatusID)
		OR NOT (dc.MifidCategorizationID <=> a.MifidCategorizationID)					
		OR NOT (CAST(dc.IsEmailVerified AS INT) <=> CAST(a.IsEmailVerified AS INT))	
		OR NOT (dc.DesignatedRegulationID <=> a.DesignatedRegulationID)	
		OR NOT (dc.RegionByIP_ID <=> a.RegionByIP_ID)	
		OR NOT (dc.RegionID <=> a.RegionID)	
		OR NOT (CAST(dc.HasWallet AS INT) <=> CAST(a.HasWallet AS INT))	
		OR NOT (dc.PhoneVerifiedID <=> a.PhoneVerifiedID)	
		OR NOT (dc.CitizenshipCountryID <=> a.CitizenshipCountryID)
		OR NOT (dc.PlayerStatusSubReasonID <=> a.PlayerStatusSubReasonID)
		OR NOT (dc.PrivacyPolicyID <=> a.PrivacyPolicyID)
		OR NOT (dc.CashoutFeeGroupID <=> a.CashoutFeeGroupID)
		OR NOT (dc.IsValidCustomer <=> a.IsValidCustomer)
		OR NOT (dc.IsCreditReportValidCB <=> a.IsCreditReportValidCB)
		OR NOT (dc.SalesForceAccountID <=> a.SalesForceAccountID)
		OR NOT (dc.POBCountryID <=> a.POBCountryID)
		OR NOT (dc.WeekendFeePrecentage <=> a.WeekendFeePrecentage)


	;
DROP VIEW IF EXISTS TEMP_TABLE_full_list;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_full_list  
 AS


SELECT 
	    a.GCID
      , a.CID
      , a.OriginalCID
      , a.UserName
      , a.FirstName
      , a.LastName
	  , a.MiddleName
      , a.Gender
      , a.BirthDate
      , a.ReferralID
      , a.CountryID
      , a.IP
      , a.AffiliateID
      , a.CampaignID
      , a.LabelID
      , a.LanguageID
      , a.Email
      , a.Phone
      , a.Zip
      , a.City
      , a.Address
	  , a.BuildingNumber
      , a.VerificationLevelID
      , a.PlayerStatusID
      , a.FunnelID
      , a.DownloadID
      , a.Registered
      , a.FunnelFromID
      , a.RiskStatusID
      , a.RiskClassificationID
      , a.EmployeeAccount
      , a.CommunicationLanguageID
      , a.BannerID
      , a.GuruStatusID
      , a.AccountTypeID
      , a.RegulationID
      , a.PlayerLevelID
      , a.AccountStatusID
      , a.AccountManagerID
      , a.ID
      , a.ExternalID
      , a.PlayerStatusReasonID
      , a.PendingClosureStatusID
      , a.CountryIDByIP
      , a.SubSerialID
      , a.EvMatchStatus
      , a.DocumentStatusID
      , a.RegulationChangeDate
      , a.IsCopyBlocked
     -- , WorldCheckID
      , a.IsEDD
	  , a.SuitabilityTestStatusID
	  , a.MifidCategorizationID
	  , CAST(a.IsEmailVerified AS INT)
	  , a.IsValidCustomer
	  --, ISNULL(FA.[2FA],0) as [2FA]      -- 17.4.23 Eitan   before
	  , COALESCE(FA.`2FA`, d.`2FA`) as `2FA`  --17.4.23 Eitan  - after
	  , a.DesignatedRegulationID
	  , a.RegionByIP_ID
	  , a.RegionID
	  , COALESCE(CAST(a.HasWallet AS INT), 0) as HasWallet
	  , a.PhoneVerifiedID
	  , a.CitizenshipCountryID
	  , a.PlayerStatusSubReasonID
	  , a.PrivacyPolicyID
	  , a.CashoutFeeGroupID
	  , a.IsCreditReportValidCB
	  , a.SalesForceAccountID
	  , a.POBCountryID
	  , a.WeekendFeePrecentage
FROM TEMP_TABLE_customer a
	LEFT JOIN TEMP_TABLE_new b
		ON a.CID = b.CID
	LEFT JOIN TEMP_TABLE_update c
		ON a.CID = c.CID 
	left join dwh_daily_process.migration_tables.Ext_Dim_Customer_2FA FA
	    on a.GCID = FA.GCID
LEFT JOIN dwh_daily_process.migration_tables.Dim_Customer d ON a.GCID=d.GCID  -- --17.4.23 Eitan  join to get last value of 2FA
WHERE b.CID IS NOT NULL OR c.CID IS NOT NULL 



	;
DROP VIEW IF EXISTS TEMP_TABLE_CustomerInitalIndicaton;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_CustomerInitalIndicaton AS
Select 
	RealCID,
	FirstDepositAmount,
	FirstDepositDate,
	HasAvatar,
	IsDepositor,
	ScreeningStatusID,
	SalesForceAccountID,
	IsAddressProof,
	IsAddressProofExpiryDate,
	IsIDProof,
	IsIDProofExpiryDate,
	WorldCheckID,
	WorldCheckResultsUpdated
	
	FROM 
	dwh_daily_process.migration_tables.Dim_Customer  WHERE EXISTS (SELECT NULL FROM TEMP_TABLE_full_list WHERE CID=Dim_Customer.RealCID)


;
-- [stub] EXIT HANDLER block elided (Databricks lets exceptions bubble)

	DELETE FROM dwh_daily_process.migration_tables.Dim_Customer  WHERE EXISTS (SELECT NULL FROM TEMP_TABLE_full_list WHERE CID=Dim_Customer.RealCID)

;
	INSERT INTO dwh_daily_process.migration_tables.Dim_Customer 
(GCID
		  ,RealCID
		  ,OriginalCID
		  ,UserName
		  ,FirstName
		  ,LastName
		  ,MiddleName
		  ,Gender
		  ,BirthDate
		  ,ReferralID
		  ,CountryID
		  ,IP
		  ,AffiliateID
		  ,CampaignID
		  ,LabelID
		  ,LanguageID
		  ,Email
		  ,Phone
		  ,Zip
		  ,City
		  ,Address
		  ,BuildingNumber
		  ,VerificationLevelID
		  ,PlayerStatusID
		  ,FunnelID
		  ,DownloadID
		  ,RegisteredReal
		  ,FunnelFromID
		  ,RiskStatusID
		  ,RiskClassificationID
		  ,EmployeeAccount
		  ,CommunicationLanguageID
		  ,BannerID
		  ,GuruStatusID
		  ,AccountTypeID
		  ,RegulationID
		  ,PlayerLevelID
		  ,AccountStatusID
		  ,AccountManagerID
		  ,ID
		  ,ExternalID
		  ,PlayerStatusReasonID
		  ,PendingClosureStatusID
		  ,CountryIDByIP
		  ,SubSerialID
		  ,EvMatchStatus
		  ,DocumentStatusID
		  ,RegulationChangeDate
		  ,IsCopyBlocked
		 -- ,WorldCheckID
		  ,IsEDD
		  ,SuitabilityTestStatusID
		  ,MifidCategorizationID
		  ,UpdateDate
		  ,IsEmailVerified
		  ,IsValidCustomer
		  ,`2FA`
		  ,DesignatedRegulationID
		  ,RegionByIP_ID
		  ,RegionID
		  ,HasWallet
		  ,PhoneVerifiedID
		  ,CitizenshipCountryID
		  ,PlayerStatusSubReasonID
		  ,PrivacyPolicyID
		  ,CashoutFeeGroupID
		  ,IsCreditReportValidCB
		---  ,SalesForceAccountID
		  ,POBCountryID
		  ,WeekendFeePrecentage
		  --- for old clients + new clients
		  ,FirstDepositAmount
		  ,FirstDepositDate
		  ,HasAvatar
		  ,IsDepositor
		  ,ScreeningStatusID
		  ,SalesForceAccountID
		  ,IsAddressProof
		  ,IsAddressProofExpiryDate
		  ,IsIDProof
		  ,IsIDProofExpiryDate
		  ,WorldCheckID
		  ,WorldCheckResultsUpdated
		  )

		  SELECT GCID
		  ,CID
		  ,OriginalCID
		  ,UserName
		  ,FirstName
		  ,LastName
		  ,MiddleName
		  ,Gender
		  ,BirthDate
		  ,ReferralID
		  ,CountryID
		  ,IP
		  ,COALESCE(AffiliateID, 0) AS AffiliateID
		  ,COALESCE(CampaignID, 0) AS CampaignID
		  ,LabelID
		  ,LanguageID
		  ,Email
		  ,Phone
		  ,Zip
		  ,City
		  ,Address
		  ,BuildingNumber
		  ,COALESCE(VerificationLevelID, 0) AS VerificationLevelID
		  ,COALESCE(PlayerStatusID, 0) AS PlayerStatusID
		  ,COALESCE(FunnelID, 0) AS FunnelID
		  ,COALESCE(DownloadID, 0) AS DownloadID
		  ,Registered
		  ,COALESCE(FunnelFromID, 0) AS FunnelFromID
		  ,COALESCE(RiskStatusID, 0) AS RiskStatusID
		  ,COALESCE(RiskClassificationID, 200) AS RiskClassificationID
		  ,EmployeeAccount 
		  ,COALESCE(CommunicationLanguageID, 0) AS CommunicationLanguageID
		  ,COALESCE(BannerID, 0) AS BannerID
		  ,COALESCE(GuruStatusID, 0) AS GuruStatusID
		  ,COALESCE(AccountTypeID, 0) AS AccountTypeID
		  ,COALESCE(RegulationID, 0) AS RegulationID
		  ,COALESCE(PlayerLevelID, 0) AS PlayerLevelID
	      ,COALESCE(AccountStatusID, 0) AS AccountStatusID
		  ,COALESCE(AccountManagerID, 0) AS AccountManagerID
		  ,ID
		  ,ExternalID
		  ,PlayerStatusReasonID
		  ,PendingClosureStatusID
		  ,CountryIDByIP
		  ,SubSerialID
		  ,EvMatchStatus
		  ,COALESCE(DocumentStatusID, 0) AS DocumentStatusID
		  ,RegulationChangeDate
		  ,IsCopyBlocked
		 -- ,WorldCheckID
		  ,IsEDD
		  ,SuitabilityTestStatusID
		  ,MifidCategorizationID
		  ,current_timestamp()
		  ,CAST(IsEmailVerified AS INT)
		  ,IsValidCustomer
		  , `2FA`
		  ,DesignatedRegulationID
		  ,RegionByIP_ID
		  ,RegionID
		  ,CAST(HasWallet AS INT)
		  ,PhoneVerifiedID
		  ,CitizenshipCountryID
		  ,PlayerStatusSubReasonID
		  ,PrivacyPolicyID
		  ,CashoutFeeGroupID
		  ,IsCreditReportValidCB
		 ---------------------
		  ,POBCountryID
		  ,WeekendFeePrecentage
		  ,b.FirstDepositAmount
		  ,COALESCE(b.FirstDepositDate, TIMESTAMP '1900-01-01')
		  ,b.HasAvatar
		  ,COALESCE(CAST(b.IsDepositor AS BOOLEAN), FALSE) as IsDepositor
		  ,b.ScreeningStatusID
		  ,b.SalesForceAccountID
		  ,b.IsAddressProof
		  ,b.IsAddressProofExpiryDate
		  ,b.IsIDProof
		  ,b.IsIDProofExpiryDate
		  ,b.WorldCheckID
		  ,b.WorldCheckResultsUpdated
	FROM TEMP_TABLE_full_list a
	LEFT JOIN TEMP_TABLE_CustomerInitalIndicaton b
	on a.CID = b.RealCID


	;

SET V_rnum = (
SELECT
count(*) from TEMP_TABLE_full_list
  LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
/************************  END INSERT TRANSACTION ***************************/


 /************************  UPDATE AVATAR AND Depositor Data  ***************************/

-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_avatar;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_avatar  
 AS

SELECT
RealCID,Avatars.HasAvatar 
FROM dwh_daily_process.migration_tables.Dim_Customer a
	----20220122---LEFT OUTER 
	JOIN (SELECT CID, 1 HasAvatar
					  FROM (
							SELECT DISTINCT CID
							FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Avatars 

							EXCEPT

							SELECT CID
							FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Avatars 
							WHERE ImageURL LIKE '%default-avatars%' OR ImageURL LIKE '%avatoros%'
						   ) a
					 ) Avatars
		ON a.RealCID = Avatars.CID
WHERE
	NOT (a.HasAvatar <=> Avatars.HasAvatar)
	----ISNULL(Dim_Customer.HasAvatar,99) <> ISNULL(Avatars.HasAvatar,99)
-- 2022-01-18 Boris  + Daniel + Reem - Change condition for update only relevant columns



	
;
SET V_avtar_rn = (
SELECT
count(*) FROM TEMP_TABLE_avatar
  LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_deposit;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_deposit  
 AS

SELECT distinct a.CID, a.FTD, 1 AS IsDepositor, a.FTDAmount
FROM dwh_daily_process.migration_tables.Ext_etoro_Billing_vDeposit a
	JOIN dwh_daily_process.migration_tables.Dim_Customer b
		ON a.CID = b.RealCID
WHERE 
a.FTD < V_end;
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN TEMP_TABLE_deposit deposit ON A.RealCID = deposit.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
IsDepositor = COALESCE(CAST(deposit.IsDepositor AS BOOLEAN), FALSE) --,FirstDepositDate = isnull(deposit.Occurred, '1900-01-01 00:00:00.000')
 --,FirstDepositAmount = deposit.Payment
 ,
FirstDepositDate = COALESCE(deposit.FTD, TIMESTAMP '1900-01-01') ,
FirstDepositAmount = deposit.FTDAmount ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_ScreeningStatusID B ON A.RealCID = B.CID --Where B.ScreeningStatusID <> isnull(A.ScreeningStatusID, -1)
 /*
UPDATE A
SET
WorldCheckID = B.WorldCheckID ,
WorldCheckResultsUpdated = B.WorldCheckResultsUpdated
,UpdateDate = GETDATE()
FROM dwh_daily_process.migration_tables.Dim_Customer A
JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_WorldCheck B
ON A.RealCID=B.CID
Where B.WorldCheckID <> isnull(A.WorldCheckID, -1)*/


QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
ScreeningStatusID = B.ScreeningStatusID ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_SF_ID B ON A.RealCID = B.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
SalesForceAccountID = B.SF_ID ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_Document B ON A.RealCID = B.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
`IsAddressProof` = B.`IsAddressProof` ,
`IsAddressProofExpiryDate` = B.`IsAddressProofExpiryDate` ,
`IsIDProof` = B.`IsIDProof` ,
`IsIDProofExpiryDate` = B.`IsIDProofExpiryDate` ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer C
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_2FA FA on C.GCID = FA.GCID

QUALIFY ROW_NUMBER() OVER (PARTITION BY C.GCID ORDER BY 1) = 1
)
ON C.GCID = A_TGT.GCID
WHEN MATCHED THEN UPDATE SET
`2FA` = FA.`2FA` ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_Affiliate B on A.AffiliateID = B.AffiliateID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.AffiliateID ORDER BY 1) = 1
)
ON A.AffiliateID = A_TGT.AffiliateID
WHEN MATCHED THEN UPDATE SET
SubChannelID = B.SubChannelID ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_CustomerStatic B on A.RealCID = B.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
ApexID = B.ApexID ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_PhoneVerificationDetails B on A.RealCID = B.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
PhoneNumber = B.PhoneNumber ,
IsPhoneVerified = B.IsPhoneVerified ,
PhoneVerificationDate = B.PhoneVerificationDate ,
UpdateDate = current_timestamp();
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Customer A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification B on A.RealCID = B.CID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
TanganyID = B.TanganyID ,
TanganyStatusID = B.TanganyStatusID ,
UpdateDate = current_timestamp();
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Customer_ExternalID_GCID

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Customer_ExternalID_GCID
    (`RealCID`
    ,`GCID`
    ,`ExternalID`
	,`UpdateDate`)
SELECT `RealCID`
    ,`GCID`
    ,`ExternalID` 
	,current_timestamp()
	FROM dwh_daily_process.migration_tables.Dim_Customer
	
;
UPDATE dwh_daily_process.migration_tables.Dim_Customer SET UserName_Lower = Lower ( UserName );
END;
