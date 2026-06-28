BEGIN



DECLARE V_ddate date ;

DECLARE V_MaxFullDate DATE 
;
DECLARE V_StartDate DATE 
;
DECLARE V_EndDate DATE;
/********************************************************************************************  
Author:      <Boris Slutski>
Create Date: <2021-09-13>
Description: SP intended to transfer data from DataLake to synapse
**************************  
** Change History  
**************************  
Date           Author     Description   
-----------  ----------  ------------------------------------  
2025-05-13    Daniel K     Add 5 HistoryCosts Dictionaries Tables
********************************************************************************************/
----- EXEC [DWH_dbo].[SP_Dictionaries_DL_To_Synapse]

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate
(`AffiliateID`
,`DateCreated`
,`MarketingExpenseID`
,`MarketingExpenseName`
,`Contact`
,`AffiliatesGroupsName`
,`ContractName`
,`Channel`
,`newContact`
,`AccountActivated`
,`LoginName`
,`UserName1`
,`UserName2`
,`UserName3`
,`UserName4`
,`Email`
,`CompanyAddress`
,`City`
,`CountryID`
,`WebSiteURL`
,`LanguageName`
,`WebSiteTitle`
,`GCID`
,`EntityName`
,`ContactPersonFullName`
,`Telephone`)
SELECT							a.AffiliateID
,a.DateCreated 
,a.MarketingExpenseID
,b.MarketingExpenseName 
,case when a.Contact is null or a.Contact =' '  then COALESCE(a.EntityName , a.Contact) else a.Contact end AS Contact
,c.AffiliatesGroupsName
,afftype.Description AS ContractName
,CASE
WHEN COALESCE(b.MarketingExpenseName, 'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' --**
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE COALESCE(b.MarketingExpenseName, 'Direct')
END AS Channel
,REPLACE(LOWER(case when a.Contact is null or a.Contact =' '  then COALESCE(a.EntityName , a.Contact) else a.Contact end), 'nonbrand', 'paid')    AS newContact
,a.AccountStatus as AccountActivated
,a.LoginName
,cast(COALESCE(pd1.Username, '"') as STRING)  AS UserName1
,cast(COALESCE(pd2.Username, '"') as STRING)  AS UserName2 
,cast(COALESCE(pd3.Username, '"') as STRING)  AS UserName3
,cast(a.LoginName as STRING) AS UserName4
,a.Email
,a.CompanyAddress
,a.City
,a.CountryID
,a.WebSiteURL
,lan.LanguageName
,a.`WebSiteTitle`
,a.`GCID`
,a.`EntityName`
,a.`ContactPersonFullName`
,a.`Telephone`
FROM dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_Affiliates AS a  
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_MarketingExpense AS b  ON a.MarketingExpenseID = b.MarketingExpenseID 
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_AffiliatesGroups AS c  ON a.AffiliatesGroupsID = c.AffiliatesGroupsID 
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_AffiliateTypes AS afftype  ON a.AffiliateTypeID = afftype.AffiliateTypeID
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_PaymentDetails pd1  ON a.PaymentDetailsID = pd1.PaymentDetailsID
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_PaymentDetails pd2  ON a.PaymentDetails2ID = pd2.PaymentDetailsID
LEFT OUTER JOIN dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_PaymentDetails pd3  ON a.PaymentDetails3ID = pd3.PaymentDetailsID
left join dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_Languages lan on lan.LanguageID = a.CommunicationLangID

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer
(`CID`
,`UserName`)
select CID,UserName
from dwh_daily_process.daily_snapshot.etoro_Customer_Customer 

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTD;

--Alter by Noga 3/11/22
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTD
(`AffiliateID`
,`FTDFirstDate`
,`FTDLastDate`
,`FTDLifeTime`
,`FTDYesterday`
,`FTDLastMonth`
,`FTDLastQuarter`
,`FTDLastYear`
,`FTDThisMonth`
,`FTDThisQuarter`
,`FTDThisYear`)

SELECT  
	cpa.AffiliateID
	--,cpa.CID As Real_CID  ---<<<<< optional, New column
	,min(cpa.CreditDate) FTDFirstDate
	,max(cpa.CreditDate) FTDLastDate
	,SUM(CAST(cpa.IsFirstDeposit as INT)) FTDLifeTime
	,sum(case when cpa.CreditDate >= DATEADD(DAY, -1, CAST(current_timestamp() AS DATE)) and cpa.CreditDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE)) then  1 else 0 end) AS FTDYesterday
	,sum(case when cpa.CreditDate > LAST_DAY(DATEADD(MONTH, -2, current_timestamp())) and cpa.CreditDate < DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS FTDLastMonth
	,sum(case when cpa.CreditDate >= ADD_MONTHS(DATE_TRUNC('QUARTER', current_timestamp()), -3) and  cpa.CreditDate < DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS FTDLastQuarter
	,sum(case when cpa.CreditDate >= ADD_MONTHS(DATE_TRUNC('YEAR', current_timestamp()), -12) and cpa.CreditDate < DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS FTDLastYear
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS FTDThisMonth
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS FTDThisQuarter
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS FTDThisYear
FROM dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_Credit cpa  
INNER JOIN  dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_CreditCommission cc  
ON cpa.CreditID = cc.CreditID AND cc.Tier=1
WHERE  cpa.CreditTypeID=1 AND 
       CAST(cpa.IsFirstDeposit as INT) = 1 AND
	   cpa.CreditDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE))
GROUP  BY cpa.AffiliateID; --,cpa.CID
--SELECT  
--tblCommissions.AffiliateID
--,min(cpa.DepositDate) FTDFirstDate
--,max(cpa.DepositDate) FTDLastDate
--,SUM(CAST(cpa.Optional2 as INT)) FTDLifeTime
--,sum(case when cpa.DepositDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDYesterday
--,sum(case when cpa.DepositDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.DepositDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDLastMonth
--,sum(case when cpa.DepositDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.DepositDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDLastQuarter
--,sum(case when cpa.DepositDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.DepositDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDLastYear
--,sum(case when cpa.DepositDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDThisMonth
--,sum(case when cpa.DepositDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDThisQuarter
--,sum(case when cpa.DepositDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_CPA] cpa with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_CPA_Commissions] tblCommissions with(nolock)         ON tblCommissions.DepositID = cpa.DepositID
--WHERE  tblCommissions.Tier=1 and CAST(cpa.Optional2 as INT) = 1 and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0)
--GROUP  BY tblCommissions.AffiliateID
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTDe;

--Alter by Noga 3/11/22
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTDe
(`AffiliateID`
,`FTDeFirstDate`
,`FTDeLastDate`
,`FTDeLifeTime`
,`FTDeYesterday`
,`FTDeLastMonth`
,`FTDeLastQuarter`
,`FTDeLastYear`
,`FTDeThisMonth`
,`FTDeThisQuarter`
,`FTDeThisYear`)
SELECT
	cpa.AffiliateID,
	--cpa.CID As Real_CID,  ---<<<<< optional, New column
	min(cpa.CreditDate) FTDeFirstDate,
	max(cpa.CreditDate) FTDeLastDate,
	SUM(CAST(cpa.IsFirstDeposit as INT)) FTDeLifeTime,
	 sum(case when cpa.CreditDate >= DATEADD(DAY, -1, CAST(current_timestamp() AS DATE)) and cpa.CreditDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE)) then  1 else 0 end) AS FTDeYesterday
	 ,sum(case when cpa.CreditDate > LAST_DAY(DATEADD(MONTH, -2, current_timestamp())) and cpa.CreditDate < DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS FTDeLastMonth
	,sum(case when cpa.CreditDate >= ADD_MONTHS(DATE_TRUNC('QUARTER', current_timestamp()), -3) and  cpa.CreditDate < DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS FTDeLastQuarter
	,sum(case when cpa.CreditDate >= ADD_MONTHS(DATE_TRUNC('YEAR', current_timestamp()), -12) and cpa.CreditDate < DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS FTDeLastYear
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS FTDeThisMonth
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS FTDeThisQuarter
	,sum(case when cpa.CreditDate >=  DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS FTDeThisYear
FROM  dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_Credit cpa   
INNER JOIN dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_CreditCommission cc  
ON cpa.CreditID = cc.CreditID 
AND cc.Tier=1 
WHERE  cpa.CreditTypeID=1 AND 
       cpa.Valid = 1 AND 
	   CAST(cpa.IsFirstDeposit as INT) = 1 AND 
	   cpa.CreditDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE))
GROUP  BY cpa.AffiliateID; --,cpa.CID

--SELECT
--tblCommissions.AffiliateID
--,min(cpa.DepositDate) FTDeFirstDate
--,max(cpa.DepositDate) FTDeLastDate
--,SUM(CAST(cpa.Optional2 as INT)) FTDeLifeTime
-- ,sum(case when cpa.DepositDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDeYesterday
-- ,sum(case when cpa.DepositDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.DepositDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeLastMonth
--,sum(case when cpa.DepositDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.DepositDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeLastQuarter
--,sum(case when cpa.DepositDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.DepositDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeLastYear
--,sum(case when cpa.DepositDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeThisMonth
--,sum(case when cpa.DepositDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeThisQuarter
--,sum(case when cpa.DepositDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_CPA] cpa with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_CPA_Commissions] tblCommissions  with(nolock)	ON tblCommissions.DepositID = cpa.DepositID 
--WHERE tblCommissions.Tier=1 and cpa.Valid = 1 and CAST(cpa.Optional2 as INT) = 1 and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0)
--GROUP  BY	tblCommissions.AffiliateID
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate_MasterAffiliate

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate_MasterAffiliate
(`AffiliateID`
,`MasterAffiliateID`)
SELECT a.`NewMemberID` AffiliateID
,a.`AffiliateID` MasterAffiliateID
FROM dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_Tier2Members a

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Registrations;
--Alter by Noga 3/11/22
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Registrations
(`AffiliateID`
,`RegistrationFirstDate`
,`RegistrationLastDate`
,`RegistrationLifeTime`
,`RegistrationYesterday`
,`RegistrationLastMonth`
,`RegistrationLastQuarter`
,`RegistrationLastYear`
,`RegistrationThisMonth`
,`RegistrationThisQuarter`
,`RegistrationThisYear`)

SELECT 
	Registrations.AffiliateID
	--,Registrations.CID As Real_CID  ---<<<<< optional, New column
	,min(Registrations.RegistrationDate)  RegistrationFirstDate
	,max(Registrations.RegistrationDate)  RegistrationLastDate
	,Count(Registrations.RegistrationID) AS RegistrationLifeTime
	,sum(case when Registrations.RegistrationDate >= DATEADD(DAY, -1, CAST(current_timestamp() AS DATE)) and Registrations.RegistrationDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE)) then  1 else 0 end) AS RegistrationYesterday
	,sum(case when Registrations.RegistrationDate > LAST_DAY(DATEADD(MONTH, -2, current_timestamp())) and Registrations.RegistrationDate < DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS RegistrationLastMonth
	,sum(case when Registrations.RegistrationDate >= ADD_MONTHS(DATE_TRUNC('QUARTER', current_timestamp()), -3) and Registrations.RegistrationDate < DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS RegistrationLastQuarter
	,sum(case when Registrations.RegistrationDate >= ADD_MONTHS(DATE_TRUNC('YEAR', current_timestamp()), -12) and Registrations.RegistrationDate < DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS RegistrationLastYear
	,sum(case when Registrations.RegistrationDate >= DATE_TRUNC('MONTH', current_timestamp()) then  1 else 0 end) AS RegistrationThisMonth
	,sum(case when Registrations.RegistrationDate >= DATE_TRUNC('QUARTER', current_timestamp()) then  1 else 0 end) AS RegistrationThisQuarter
	,sum(case when Registrations.RegistrationDate >= DATE_TRUNC('YEAR', current_timestamp()) then  1 else 0 end) AS RegistrationThisYear
FROM   dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_Registration Registrations  
INNER JOIN dwh_daily_process.daily_snapshot.fiktivo_AffiliateCommission_RegistrationCommission RC 
ON Registrations.RegistrationID = RC.RegistrationID 
AND RC.Tier=1
WHERE Registrations.RegistrationDate < DATEADD(DAY, 0, CAST(current_timestamp() AS DATE))
group by Registrations.AffiliateID; --,Registrations.CID

--SELECT 
--tblCommissions.AffiliateID
--,min(Registrations.ORDER_DATE)  RegistrationFirstDate
--,max(Registrations.ORDER_DATE)  RegistrationLastDate
--,Count(Registrations.RegistrationID) AS RegistrationLifeTime
--,sum(case when Registrations.ORDER_DATE >= dateadd(day,datediff(day,1,GETDATE()),0) and Registrations.ORDER_DATE < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS RegistrationYesterday
--,sum(case when Registrations.ORDER_DATE > EOMONTH(DATEADD(mm,-2,getdate())) and Registrations.ORDER_DATE < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationLastMonth
--,sum(case when Registrations.ORDER_DATE >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and Registrations.ORDER_DATE < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationLastQuarter
--,sum(case when Registrations.ORDER_DATE >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and Registrations.ORDER_DATE < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationLastYear
--,sum(case when Registrations.ORDER_DATE >= DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationThisMonth
--,sum(case when Registrations.ORDER_DATE >= DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationThisQuarter
--,sum(case when Registrations.ORDER_DATE >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_Registrations] Registrations with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_Registrations_Commissions] tblCommissions with(nolock)	ON Registrations.RegistrationID = tblCommissions.RegistrationID
--WHERE tblCommissions.Tier=1 and Registrations.ORDER_DATE < dateadd(day,datediff(day,0,GETDATE()),0)
--group by tblCommissions.AffiliateID
call dwh_daily_process.migration_tables.SP_Dim_Affiliate();
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_BonusType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_BonusType
           (`BonusTypeID`
           ,`Name`
           ,`IsWithdrawable`
           ,`IsActive`
           ,`DWHBonusTypeID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
SELECT BonusTypeID,
	   Name,
	   IsWithdrawable,
	   CAST(IsActive AS INT),
	   BonusTypeID AS DWHBonusTypeID,
	   1 as StatusID,
	   current_timestamp() as UpdateDate,
	   current_timestamp() as InsertDate
FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_BonusType;

--------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_EvMatchStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_EvMatchStatus
(
`EvMatchStatusID`
,`EvMatchStatusName`
,`UpdateDate`
)
SELECT 
`EvMatchStatusId`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.UserApiDB_Dictionary_EvMatchStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ExtendedUserField

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ExtendedUserField
(`FieldID`
,`FieldTypeID`
,`ExtendedUserFieldName`
,`UpdateDate`)
SELECT 
`FieldId`
,`FieldTypeId`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.UserApiDB_Dictionary_ExtendedUserField;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_VerificationStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_VerificationStatus
(`VerificationStatusID`
,`Name`
,`UpdateDate`)
SELECT 
`VerificationStatusID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.UserApiDB_Dictionary_VerificationStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_AccountStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_AccountStatus
(`AccountStatusID`
,`AccountStatusName`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`AccountStatusID`
,`AccountStatusName`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_AccountStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_AccountType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_AccountType
(`AccountTypeID`
,`Name`
,`DWHAccountTypeID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`AccountTypeID`
,`AccountTypeName`
,`AccountTypeID` as `DWHAccountTypeID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_AccountType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CashoutFeeGroup

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CashoutFeeGroup
(`CashoutFeeGroupID`
,`CashoutFeeGroupName`
,`UpdateDate`)
SELECT 
`CashoutFeeGroupID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CashoutFeeGroup;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CashoutStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CashoutStatus
(`CashoutStatusID`
,`Name`
,`DWHCashoutStatusID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`CashoutStatusID`
,`Name`
,`CashoutStatusID` as `DWHCashoutStatusID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CashoutStatus


;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Channel

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Channel
           (`AffiliateID`
           ,`DateCreated`
           ,`MarketingExpenseID`
           ,`MarketingExpenseName`
           ,`Contact`
           ,`AffiliatesGroupsName`
           ,`ContractName`
           ,`Channel`
           ,`newContact`)
select a.AffiliateID
,a.DateCreated
,a.MarketingExpenseID 
,b.MarketingExpenseName 
,a.Contact 
,c.AffiliatesGroupsName 
,`Description` as ContractName
,CASE
WHEN COALESCE(b.MarketingExpenseName, 'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'				
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' 
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE COALESCE(b.MarketingExpenseName, 'Direct')
END AS Channel
,replace(lower(a.Contact) ,'nonbrand','paid') as newContact 
FROM dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_Affiliates a
left join dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_MarketingExpense b  on a.MarketingExpenseID=b.MarketingExpenseID
left join dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_AffiliatesGroups c  on a.AffiliatesGroupsID = c.AffiliatesGroupsID
left join dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_AffiliateTypes afftype  on a.`AffiliateTypeID`=afftype.`AffiliateTypeID`;
----------------------------------------------
call dwh_daily_process.migration_tables.SP_Dim_Channel();
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ClientWithdrawReason

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ClientWithdrawReason
(`ClientWithdrawReasonID`
,`ClientWithdrawReasonName`
,`UpdateDate`)
SELECT 
`ClientWithdrawReasonID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_ClientWithdrawReason;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ClosePositionReason

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ClosePositionReason
(`ClosePositionReasonID`
,`Name`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`ID`
,`ClosePositionActionName`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_ClosePositionActionType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CountryBin

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CountryBin
(`CountryID`
,`BinCode`
,`IssuingBank`
,`CardTypeID`
,`CardSubType`
,`CardCategory`
,`BankWebSite`
,`BankInfo`
,`ShouldCheck3ds`
,`MinAmountFor3ds`
,`IsPrepaid`
,`UpdateDate`)
SELECT 
`CountryID`
,`BinCode`
,`IssuingBank`
,`CardTypeID`
,`CardSubType`
,`CardCategory`
,`BankWebSite`
,`BankInfo`
,`ShouldCheck3ds`
,`MinAmountFor3ds`
,`IsPrepaid`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CountryBin;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CountryIP

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CountryIP
(`CountryID`
,`IPFrom`
,`IPTo`
,`RegionID`
,`UpdateDate`)
SELECT 
`CountryID`
,`IPFrom`
,`IPTo`
,`RegionID`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CountryIP;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CreditType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CreditType
(`CreditTypeID`
,`CreditTypeName`
,`UpdateDate`)
SELECT 
`CreditTypeID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CreditType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Currency

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Currency
(`CurrencyID`
,`CurrencyTypeID`
,`Name`
,`Abbreviation`
,`Mask`
,`EEAStockExchange`
,`ISINCode`
,`CurrencySymbol`
,`InterestRateID`
,`UpdateDate`)
SELECT 
`CurrencyID`
,`CurrencyTypeID`
,`Name`
,`Abbreviation`
,`Mask`
,`EEAStockExchange`
,`ISINCode`
,`CurrencySymbol`
,`InterestRateID`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Currency;


----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_BillingDepot

;
INSERT INTO dwh_daily_process.migration_tables.Dim_BillingDepot
           (`DepotID`
           ,`FundingTypeID`
           ,`PaymentTypeID`
           ,`ProtocolID`
           ,`Name`
           ,`IsActive`
           ,`UpdateDate`)
select 
`DepotID`
,`FundingTypeID`
,`PaymentTypeID`
,`ProtocolID`
,`Name`
,CAST(IsActive AS INT)
, current_timestamp() as UpdateDate
 FROM dwh_daily_process.daily_snapshot.etoro_Billing_Depot;


----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_DocumentStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_DocumentStatus
(`DocumentStatusID`
,`DocumentStatusName`
,`UpdateDate`)
SELECT 
`DocumentStatusID`
,`DocumentStatusName`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_DocumentStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ExchangeInfo

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ExchangeInfo
(`ExchangeID`
,`ExchangeDescription`
,`UpdateDate`)
SELECT 
`ExchangeID`
,`ExchangeDescription`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_ExchangeInfo;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_FundType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_FundType
(`FundTypeID`
,`FundTypeName`
,`UpdateDate`)
SELECT 
`FundTypeID`
,`Description`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_FundType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Fund

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Fund
           (`FundID`
           ,`FundName`
           ,`FundAccountID`
           ,`FundOwnerID`
           ,`IsPublic`
           ,`MinCopyAmount`
           ,`RefreshIntervalMonths`
           ,`FundType`
           ,`UpdateDate`)

SELECT `FundID`
      ,`FundName`
      ,`FundAccountID`
      ,`FundOwnerID`
      ,`IsPublic`
      ,`MinCopyAmount`
      ,`RefreshIntervalMonths`
      ,`FundType`
 ,current_timestamp() as UpdateDate
from 
dwh_daily_process.daily_snapshot.etoro_Trade_Fund;
----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_FundingType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_FundingType
(`FundingTypeID`
,`Name`
,`IsNewStyle`
,`IsSingleFunding`
,`IsCashoutActive`
,`DWHFundingTypeID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`FundingTypeID`
,`Name`
,`IsNewStyle`
,`IsSingleFunding`
,`IsCashoutActive`
,`FundingTypeID` as `DWHFundingTypeID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_FundingType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Funnel

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Funnel
(`FunnelID`
,`Name`
,`PlatformID`
,`UpdateDate`
,`InsertDate`
,`StatusID`)
SELECT 
`FunnelID`
,`Name`
,`PlatformID`
,current_timestamp()
,current_timestamp()
,1 as StatusID
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Funnel;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_GuruStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_GuruStatus
(`GuruStatusID`
,`GuruStatusName`
,`UpdateDate`)
SELECT 
`GuruStatusID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_GuruStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Label

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Label
(`LabelID`
,`Name`
,`DWHLabelID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`LabelID`
,`Name`
,`LabelID` as`DWHLabelID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Label;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Language

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Language
(`LanguageID`
,`Name`
,`DWHLanguageID`
,`StatusID`
,`UpdateDate`
,`InsertDate`
,`IsoCode`
,`CultureCode`)
SELECT 
`LanguageID`
,`Name`
,`LanguageID` as `DWHLanguageID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
,`IsoCode`
,`CultureCode`
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Language;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Manager

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Manager
           (`ManagerID`
           ,`UserGroup`
           ,`ParentUserGroup`
           ,`FirstName`
           ,`LastName`
           ,`IsActive`
           ,`IsTeamLeader`
           ,`DWHManagerID`
           ,`StatusID`
           ,`CalendlyID`)
select ManagerID,'Not Available' as UserGroup,'Not Available' as ParentUserGroup,FirstName,LastName,CAST(IsActive AS INT),IsTeamLeader, 
ManagerID as DWHManagerID, 1 as StatusID
,CalendlyID
from dwh_daily_process.daily_snapshot.etoro_BackOffice_Manager
;
MERGE INTO dwh_daily_process.migration_tables.Dim_Manager A_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Manager A
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Manager B ON A.ManagerID = B.ManagerID

QUALIFY ROW_NUMBER() OVER (PARTITION BY A.ManagerID ORDER BY 1) = 1
)
ON A.ManagerID = A_TGT.ManagerID
WHEN MATCHED THEN UPDATE SET
FirstName = B.FirstName ,
LastName = B.LastName ,
IsTeamLeader = B.IsTeamLeader ,
IsActive = CAST(B.IsActive AS INT) ,
CalendlyID = B.CalendlyID ,
UpdateDate = current_timestamp();
 INSERT INTO  dwh_daily_process.migration_tables.Dim_Manager
 (ManagerID,UserGroup,ParentUserGroup,FirstName,
 LastName,IsActive,IsTeamLeader,DWHManagerID,
 UpdateDate,InsertDate,StatusID,CalendlyID)
SELECT b.ManagerID,
b.UserGroup,
b.ParentUserGroup,
b.FirstName,
b.LastName,
CAST(b.IsActive AS INT),
b.IsTeamLeader,
b.ManagerID,
current_timestamp() as UpdateDate,
current_timestamp() as InsertDate,
1 as StatusID,
b.CalendlyID
FROM  dwh_daily_process.migration_tables.Dim_Manager a
right JOIN 
 dwh_daily_process.migration_tables.Ext_Dim_Manager b
ON(a.ManagerID=b.ManagerID)
WHERE a.ManagerID IS null
;
MERGE INTO dwh_daily_process.migration_tables.Dim_Manager A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Manager a
INNER JOIN dwh_daily_process.daily_snapshot.SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping b on a.ManagerID = b.`ManagerID`

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.ManagerID ORDER BY 1) = 1
)
ON a.ManagerID = A_TGT.ManagerID
WHEN MATCHED THEN UPDATE SET
`SFManagerID` = b.`SFManagerID`;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_MifidCategorization

;
INSERT INTO dwh_daily_process.migration_tables.Dim_MifidCategorization
(`MifidCategorizationID`
,`Name`
,`UpdateDate`)
SELECT 
`MifidCategorizationID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_MifidCategorization;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_MirrorType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_MirrorType
(`MirrorTypeID`
,`MirrorTypeName`
,`UpdateDate`)
SELECT 
`MirrorTypeID`
,`MirrorTypeName`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_MirrorType;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PaymentStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PaymentStatus
(`PaymentStatusID`
,`Name`
,`DWHPaymentStatusID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT
`PaymentStatusID`
,`Name`
,`PaymentStatusID` as `DWHPaymentStatusID`
,1 as StatusID
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PaymentStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PendingClosureStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PendingClosureStatus
(`PendingClosureStatusID`
,`PendingClosureStatusName`
,`UpdateDate`)
SELECT 
`PendingClosureStatusID`
,`PendingClosureStatusName`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PendingClosureStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PhoneVerified

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PhoneVerified
(`PhoneVerifiedID`
,`PhoneVerifiedName`
,`UpdateDate`)
SELECT 
`PhoneVerifiedID`
,`PhoneVerifiedName`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PhoneVerified;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Platform

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Platform
(`PlatformID`
,`Platform`
,`UpdateDate`)
SELECT 
`Id`
,`Platform`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Platform;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PlayerLevel

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerLevel
(`PlayerLevelID`
,`Name`
,`CashoutPendingHours`
,`FromSumLotCount`
,`ToSumLotCount`
,`FromSumDeposit`
,`ToSumDeposit`
,`Sort`
,`DWHPlayerLevelID`
,`UpdateDate`
,`InsertDate`
,`StatusID`)
SELECT 
`PlayerLevelID`
,`Name`
,`CashoutPendingHours`
,`FromSumLotCount`
,`ToSumLotCount`
,`FromSumDeposit`
,`ToSumDeposit`
,`Sort`
, `PlayerLevelID` as  `DWHPlayerLevelID`
,current_timestamp()
,current_timestamp()
,1 as `StatusID`
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PlayerLevel;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PlayerStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerStatus
(`PlayerStatusID`
,`Name`
,`IsBlocked`
,`CanEditPosition`
,`CanOpenPosition`
,`CanClosePosition`
,`CanDeposit`
,`CanRequestWithdraw`
,`CanLogin`
,`CanChatAndPost`
,`CanBeCopied`
,`DWHPlayerStatusID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`PlayerStatusID`
,`Name`
,`IsBlocked`
,`CanEditPosition`
,`CanOpenPosition`
,`CanClosePosition`
,`CanDeposit`
,`CanRequestWithdraw`
,`CanLogin`
,`CanChatAndPost`
,`CanBeCopied`
,`PlayerStatusID` as `DWHPlayerStatusID`
,1 as `StatusID`
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PlayerStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PlayerStatusReasons

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerStatusReasons
(`PlayerStatusReasonID`
,`Name`
,`UpdateDate`)
SELECT 
`PlayerStatusReasonID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PlayerStatusReasons;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_PlayerStatusSubReasons

;
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerStatusSubReasons
(`PlayerStatusSubReasonID`
,`PlayerStatusSubReasonName`
,`UpdateDate`)
SELECT 
`PlayerStatusSubReasonID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_PlayerStatusSubReasons;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_RedeemReason

;
INSERT INTO dwh_daily_process.migration_tables.Dim_RedeemReason
(`RedeemReasonID`
,`RedeemReasonName`
,`UpdateDate`)
SELECT 
`RedeemReasonID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_RedeemReason;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_RedeemStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_RedeemStatus
(`RedeemStatusID`
,`Name`
,`DisplayName`
,`IsCancelable`
,`InsertDate`
,`UpdateDate`)
SELECT 
`RedeemStatusID`
,`Name`
,`DisplayName`
,`IsCancelable`
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_RedeemStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_BillingProtocolMIDSettingsID

;
INSERT INTO dwh_daily_process.migration_tables.Dim_BillingProtocolMIDSettingsID
           (`ProtocolMIDSettingsID`
           ,`ParameterID`
           ,`DepotID`
           ,`DepotModeID`
           ,`Value`
           ,`RegulationID`
           ,`CurrencyID`
           ,`Description`
           ,`SubTypeID`
           ,`MerchantAccountID`
           ,`UpdateDate`)
SELECT 
ID AS ProtocolMIDSettingsID,
ParameterID,
DepotID,
DepotModeID,
Value,
RegulationID,
CurrencyID,
Description,
SubTypeID,
MerchantAccountID,
current_timestamp() AS UpdateDate
FROM dwh_daily_process.daily_snapshot.etoro_Billing_ProtocolMIDSettings;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Campaign;

--INSERT INTO [DWH_dbo].[Dim_Campaign]
--           ([CampaignID]
--           ,[CampaignGroupID]
--           ,[Code]
--           ,[MaxNumberOfUsers]
--           ,[StartDate]
--           ,[EndDate]
--           ,[MaxBonusAmount]
--           ,[IsActive]
--           ,[ParticipatedUsers]
--           ,[Description]
--           ,[InsertDate]
--           ,[UpdateDate])
--SELECT [CampaignID]
--      ,[CampaignGroupID]
--      ,[Code]
--      ,[MaxNumberOfUsers]
--      ,[StartDate]
--      ,[EndDate]
--      ,[MaxBonusAmount]
--      ,[CAST(IsActive AS INT)]
--      ,[ParticipatedUsers]
--      ,[Description]
--      ,GETDATE() as InsertDate
--      ,GETDATE() as UpdateDate
--  FROM [DWH_staging].[etoro_BackOffice_Campaign]

-------------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CashoutMode

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CashoutMode
           (`CashoutModeID`
           ,`CashoutModeName`
           ,`CashoutModeWeight`
           ,`UpdateDate`)
SELECT `CashoutModeID`
      ,`CashoutModeName`
      ,`CashoutModeWeight`
	  ,current_timestamp()
  FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CashoutMode;

-------------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CashoutReason

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CashoutReason
(`CashoutReasonID`
,`Name`
,`UpdateDate`)
SELECT `CashoutReasonID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_CashoutReason;


-------------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_State_and_Province

;
INSERT INTO dwh_daily_process.migration_tables.Dim_State_and_Province
           (`RegionByIP_ID`
           ,`CountryID`
           ,`ShortName`
           ,`Name`
           ,`UpdateDate`)
select 
rei.RegionByIP_ID,
ren.CountryID,
ren.ShortName,
ren.Name,
current_timestamp() as UpdateDate
from dwh_daily_process.daily_snapshot.etoro_Dictionary_RegionByIP as rei 
Join dwh_daily_process.daily_snapshot.etoro_Dictionary_RegionName as ren
On rei.Name = ren.ShortName  and rei.CountryID=ren.CountryID;

-------------------------------------------------

-- TRUNCATE TABLE [DWH_dbo].[Dim_PEPStatus]
-- INSERT INTO [DWH_dbo].[Dim_PEPStatus]
--           ([PEPStatusID]
--           ,[Name]
--           ,[UpdateDate])
-- SELECT [ID] AS PEPStatusID
--      ,[Name]
--      , getdate() as UpdateDate
--  FROM [DWH_staging].[Dim_PEPStatus]

 ----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Regulation

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Regulation
(`ID`
,`Name`
,`DWHRegulationID`
,`StatusID`
,`UpdateDate`
,`InsertDate`
,`ClusterRegulationID`)
SELECT 
`ID`
,`Name`
,`ID` as `DWHRegulationID`
,1 as `StatusID`
,current_timestamp()
,current_timestamp()
,CASE WHEN ID in (0,1,5) THEN 1 ELSE ID END as ClusterRegulationID
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Regulation;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_RiskClassification

;
INSERT INTO dwh_daily_process.migration_tables.Dim_RiskClassification
(`RiskClassificationID`
,`RiskClassificationName`
,`RiskScore`
,`UpdateDate`)
SELECT 
`RiskClassificationID`
,`Name`
,`RiskScore`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_RiskClassification;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_RiskManagementStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_RiskManagementStatus
(`RiskManagementStatusID`
,`Name`
,`DWHRiskManagementStatusID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`RiskManagementStatusID`
,`Name`
, `RiskManagementStatusID` as `DWHRiskManagementStatusID`
,1 as `StatusID`
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_RiskManagementStatus;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_RiskStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_RiskStatus
(`RiskStatusID`
,`Name`
,`IsActive`
,`DWHRiskStatusID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`RiskStatusID`
,`Name`
,CAST(IsActive AS INT)
,`RiskStatusID` as `DWHRiskStatusID`
,1 as `StatusID`
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_RiskStatus;
   
----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ThreeDsResponseTypes

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ThreeDsResponseTypes
(`ThreeDsResponseTypeID`
,`ThreeDsResponseTypesName`
,`UpdateDate`)
SELECT 
`ThreeDsResponseTypeID`
,`Name`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_ThreeDsResponseTypes;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_VerificationLevel

;
INSERT INTO dwh_daily_process.migration_tables.Dim_VerificationLevel
(`ID`
,`Name`
,`DWHVerificationLevelID`
,`StatusID`
,`UpdateDate`
,`InsertDate`)
SELECT 
`ID`
,`Name`
,`ID` as `DWHVerificationLevelID`
,1 as `StatusID`
,current_timestamp()
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_VerificationLevel;

----------------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_WorldCheck

;
INSERT INTO dwh_daily_process.migration_tables.Dim_WorldCheck
(`WorldCheckID`
,`WorldCheckName`
,`UpdateDate`)
SELECT 
`WorldCheckID`
,`WorldCheckName`
,current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_WorldCheck;


--------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CompensationReason

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CompensationReason
	  (`CompensationReasonID`
      ,`ParentID`
      ,`Name`
	  ,`DWHCompensationID`
	  ,`StatusID`
	  ,`UpdateDate`
	  ,`InsertDate`)
SELECT `CompensationReasonID`
      ,`ParentID`
      ,`Name`
      ,`CompensationReasonID`
	  ,1
	  ,current_timestamp()
	  ,current_timestamp()
  FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_CompensationReason

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ScreeningStatus

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ScreeningStatus
           (`ScreeningStatusID`
           ,`Name`
           ,`UpdateDate`)
SELECT `ID`
      ,`Name`
	  ,current_timestamp()
  FROM dwh_daily_process.daily_snapshot.ScreeningService_Dictionary_ScreeningStatus;


----------------------------------HistoryCosts-----------------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CalculationType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CalculationType
(
`CalculationTypeId`,
`CalculationType`,
`UpdateDate`)
SELECT 
`Id`,
`CalculationType`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.HistoryCosts_Dictionary_CalculationType

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CostConfigurationId

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CostConfigurationId
(
`CostConfigurationId`,
`CostConfiguration`,
`UpdateDate`)
SELECT 
`Id`,
`CostConfigurationId`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.HistoryCosts_Dictionary_CostConfigurationId

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CostSubtype

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CostSubtype
(
`CostSubtypeId`,
`CostSubtype`,
`UpdateDate`)
SELECT 
`Id`,
`CostSubtype`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.HistoryCosts_Dictionary_CostSubtype


;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CostType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CostType
(
`CostTypeId`,
`CostType`,
`UpdateDate`)
SELECT 
`Id`,
`CostType`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.HistoryCosts_Dictionary_CostType

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_ExecutionOperationType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_ExecutionOperationType
(
`OperationTypeId`,
`OperationType`,
`UpdateDate`)
SELECT 
`Id`,
`OperationType`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.HistoryCosts_Dictionary_ExecutionOperationType

;
INSERT INTO dwh_daily_process.migration_tables.Dim_FeeOperationTypes
(
`FeeOperationTypeID`,
`FeeOperationTypeName`,
`UpdateDate`)
SELECT 
`FeeOperationTypeID`,
`Name`,
current_timestamp()
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_FeeOperationTypes;
---------------------------------------------------------------------------

---- iNSERT DEFAULT VALUES 0
SET V_ddate = cast(current_timestamp() AS date)
;
INSERT INTO dwh_daily_process.migration_tables.Dim_AccountStatus
           (`AccountStatusID`
           ,`AccountStatusName`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
           (0
           ,'N/A'
           ,1
           ,V_ddate
           ,V_ddate
		   );
---------------------
INSERT INTO dwh_daily_process.migration_tables.Dim_AccountType
           (`AccountTypeID`
           ,`Name`
           ,`DWHAccountTypeID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
           (0
           ,'N/A'
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   );

-------------
INSERT INTO dwh_daily_process.migration_tables.Dim_BonusType
           (`BonusTypeID`
           ,`Name`
           ,`IsWithdrawable`
           ,`IsActive`
           ,`DWHBonusTypeID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   );

----------------
INSERT INTO dwh_daily_process.migration_tables.Dim_FundingType
           (`FundingTypeID`
           ,`Name`
           ,`IsNewStyle`
           ,`IsSingleFunding`
           ,`IsCashoutActive`
           ,`DWHFundingTypeID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   );
-------------
INSERT INTO dwh_daily_process.migration_tables.Dim_Language
           (`LanguageID`
           ,`Name`
           ,`DWHLanguageID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`
           ,`IsoCode`
           ,`CultureCode`)
     VALUES
          (0
           ,'N/A'
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   ,'N/A'
		   ,'N/A'
		   );

 --------------
INSERT INTO dwh_daily_process.migration_tables.Dim_PaymentStatus
           (`PaymentStatusID`
           ,`Name`
           ,`DWHPaymentStatusID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
	VALUES
			(-1
           ,'N/A'
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   );

 --------------
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerLevel
           (`PlayerLevelID`
           ,`Name`
           ,`CashoutPendingHours`
           ,`FromSumLotCount`
           ,`ToSumLotCount`
           ,`FromSumDeposit`
           ,`ToSumDeposit`
           ,`Sort`
           ,`DWHPlayerLevelID`
           ,`UpdateDate`
           ,`InsertDate`
           ,`StatusID`)
     VALUES
			(0
           ,'N/A'
		   ,0
           ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
           ,V_ddate
           ,V_ddate
		   ,1
		   );

---------------
INSERT INTO dwh_daily_process.migration_tables.Dim_PlayerStatus
           (`PlayerStatusID`
           ,`Name`
           ,`IsBlocked`
           ,`CanEditPosition`
           ,`CanOpenPosition`
           ,`CanClosePosition`
           ,`CanDeposit`
           ,`CanRequestWithdraw`
           ,`CanLogin`
           ,`CanChatAndPost`
           ,`CanBeCopied`
           ,`DWHPlayerStatusID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
			(0
           ,'N/A'
		   ,0
           ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,1
           ,V_ddate
           ,V_ddate
		   );
-------------
INSERT INTO dwh_daily_process.migration_tables.Dim_RedeemStatus
           (`RedeemStatusID`
           ,`Name`
           ,`DisplayName`
           ,`IsCancelable`
           ,`InsertDate`
           ,`UpdateDate`)
	VALUES
		   (0
           ,'N/A'
		   ,'N/A'
           ,1
           ,V_ddate
           ,V_ddate
		   );

-----
INSERT INTO dwh_daily_process.migration_tables.Dim_RiskManagementStatus
           (`RiskManagementStatusID`
           ,`Name`
           ,`DWHRiskManagementStatusID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
			(0
           ,'N/A'
		   ,0
           ,1
           ,V_ddate
           ,V_ddate
		   );

-------
INSERT INTO dwh_daily_process.migration_tables.Dim_CompensationReason
           (`CompensationReasonID`
           ,`ParentID`
           ,`Name`
           ,`DWHCompensationID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
           (0
		   ,Null
           ,'N/A'
		   ,0
		   ,1
           ,V_ddate
		   ,V_ddate
		   );


-----------------
INSERT INTO dwh_daily_process.migration_tables.Dim_CashoutStatus
           (`CashoutStatusID`
           ,`Name`
           ,`DWHCashoutStatusID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
			(0
           ,'N/A'
		   ,0
		   ,1
           ,V_ddate
		   ,V_ddate
		   );


-------------------
INSERT INTO dwh_daily_process.migration_tables.Dim_Campaign
           (`CampaignID`
           ,`CampaignGroupID`
           ,`Code`
           ,`MaxNumberOfUsers`
           ,`StartDate`
           ,`EndDate`
           ,`MaxBonusAmount`
           ,`IsActive`
           ,`ParticipatedUsers`
           ,`Description`
           ,`InsertDate`
           ,`UpdateDate`)
     VALUES
			(0
		   ,NULL
           ,'N/A'
		   ,0
		   ,'1900-01-01 00:00:00.000'
		   ,'1900-01-01 00:00:00.000'
		   ,0.00
		   ,0
		   ,0
		   ,NULL
           ,V_ddate
		   ,V_ddate
		   );

------------------
INSERT INTO dwh_daily_process.migration_tables.Dim_VerificationLevel
           (`ID`
           ,`Name`
           ,`DWHVerificationLevelID`
           ,`StatusID`
           ,`UpdateDate`
           ,`InsertDate`)
     VALUES
		   (-1
           ,'N/A'
		   ,-1
		   ,1
           ,V_ddate
		   ,V_ddate
		   );

--------------------------

SET V_MaxFullDate = (
SELECT
max(FullDate) FROM  dwh_daily_process.migration_tables.Dim_Date
 LIMIT 1);
IF CAST(DATEDIFF(current_timestamp(), V_MaxFullDate) / 365 AS INT)<=1
THEN

SET V_StartDate = (
SELECT
DATEADD(DAY, 1, V_MaxFullDate)  LIMIT 1);
SET V_EndDate = (
SELECT
DATEADD(YEAR, CAST(DATEDIFF(0, DATEADD(DAY, 365, V_StartDate)) / 365 AS INT) + 1, -1)  LIMIT 1);
call dwh_daily_process.migration_tables.SP_PopulateDimDate(V_StartDate,V_EndDate);
END IF; 





END