# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_ExecutionOperationType`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_ExecutionOperationType.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_ExecutionOperationType]
(
	[OperationTypeId] [int] NULL,
	[OperationType] [nvarchar](max) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[OperationTypeId] ASC
	)
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Dictionaries_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dictionaries_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dictionaries_DL_To_Synapse] AS
BEGIN

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


TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate]
([AffiliateID]
,[DateCreated]
,[MarketingExpenseID]
,[MarketingExpenseName]
,[Contact]
,[AffiliatesGroupsName]
,[ContractName]
,[Channel]
,[newContact]
,[AccountActivated]
,[LoginName]
,[UserName1]
,[UserName2]
,[UserName3]
,[UserName4]
,[Email]
,[CompanyAddress]
,[City]
,[CountryID]
,[WebSiteURL]
,[LanguageName]
,[WebSiteTitle]
,[GCID]
,[EntityName]
,[ContactPersonFullName]
,[Telephone])
SELECT							a.AffiliateID
,a.DateCreated 
,a.MarketingExpenseID
,b.MarketingExpenseName 
,case when a.Contact is null or a.Contact =' '  then isnull(a.EntityName COLLATE Latin1_General_BIN,a.Contact ) else a.Contact end AS Contact
,c.AffiliatesGroupsName
,afftype.Description AS ContractName
,CASE
WHEN isnull(b.MarketingExpenseName,'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' --**
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE isnull(b.MarketingExpenseName,'Direct')
END AS Channel
,REPLACE(LOWER(case when a.Contact is null or a.Contact =' '  then isnull(a.EntityName COLLATE Latin1_General_BIN,a.Contact) else a.Contact end), 'nonbrand', 'paid')  COLLATE Latin1_General_BIN  AS newContact
,a.AccountStatus as AccountActivated
,a.LoginName
,cast(ISNULL(pd1.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName1
,cast(ISNULL(pd2.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName2 
,cast(ISNULL(pd3.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName3
,cast(a.LoginName as varchar(50)) AS UserName4
,a.Email
,a.CompanyAddress
,a.City
,a.CountryID
,a.WebSiteURL
,lan.LanguageName
,a.[WebSiteTitle]
,a.[GCID]
,a.[EntityName]
,a.[ContactPersonFullName]
,a.[Telephone]
FROM [DWH_staging].[fiktivo_dbo_tblaff_Affiliates] AS a WITH (NOLOCK) 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_MarketingExpense] AS b WITH (NOLOCK) ON a.MarketingExpenseID = b.MarketingExpenseID 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_AffiliatesGroups] AS c WITH (NOLOCK) ON a.AffiliatesGroupsID = c.AffiliatesGroupsID 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_AffiliateTypes] AS afftype WITH (NOLOCK) ON a.AffiliateTypeID = afftype.AffiliateTypeID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd1 WITH(NOLOCK) ON a.PaymentDetailsID = pd1.PaymentDetailsID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd2 WITH(NOLOCK) ON a.PaymentDetails2ID = pd2.PaymentDetailsID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd3 WITH(NOLOCK) ON a.PaymentDetails3ID = pd3.PaymentDetailsID
left join [DWH_staging].[fiktivo_dbo_tblaff_Languages] lan on lan.LanguageID = a.CommunicationLangID

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_Customer]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_Customer]
([CID]
,[UserName])
select CID,UserName
from [DWH_staging].[etoro_Customer_Customer] with (NOLOCK)

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_FTD]

--Alter by Noga 3/11/22
INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_FTD]
([AffiliateID]
,[FTDFirstDate]
,[FTDLastDate]
,[FTDLifeTime]
,[FTDYesterday]
,[FTDLastMonth]
,[FTDLastQuarter]
,[FTDLastYear]
,[FTDThisMonth]
,[FTDThisQuarter]
,[FTDThisYear])

SELECT  
	cpa.AffiliateID
	--,cpa.CID As Real_CID  ---<<<<< optional, New column
	,min(cpa.CreditDate) FTDFirstDate
	,max(cpa.CreditDate) FTDLastDate
	,SUM(CAST(cpa.IsFirstDeposit as INT)) FTDLifeTime
	,sum(case when cpa.CreditDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDYesterday
	,sum(case when cpa.CreditDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.CreditDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDLastMonth
	,sum(case when cpa.CreditDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.CreditDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDLastQuarter
	,sum(case when cpa.CreditDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.CreditDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDLastYear
	,sum(case when cpa.CreditDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDThisMonth
	,sum(case when cpa.CreditDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDThisQuarter
	,sum(case when cpa.CreditDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDThisYear
FROM [DWH_staging].[fiktivo_AffiliateCommission_Credit] cpa with(nolock) 
INNER JOIN  [DWH_staging].[fiktivo_AffiliateCommission_CreditCommission] cc with(nolock) 
ON cpa.CreditID = cc.CreditID AND cc.Tier=1
WHERE  cpa.CreditTypeID=1 AND 
       CAST(cpa.IsFirstDeposit as INT) = 1 AND
	   cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0)
GROUP  BY cpa.AffiliateID --,cpa.CID
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
  
TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_FTDe]

--Alter by Noga 3/11/22
INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_FTDe]
([AffiliateID]
,[FTDeFirstDate]
,[FTDeLastDate]
,[FTDeLifeTime]
,[FTDeYesterday]
,[FTDeLastMonth]
,[FTDeLastQuarter]
,[FTDeLastYear]
,[FTDeThisMonth]
,[FTDeThisQuarter]
,[FTDeThisYear])
SELECT
	cpa.AffiliateID,
	--cpa.CID As Real_CID,  ---<<<<< optional, New column
	min(cpa.CreditDate) FTDeFirstDate,
	max(cpa.CreditDate) FTDeLastDate,
	SUM(CAST(cpa.IsFirstDeposit as INT)) FTDeLifeTime,
	 sum(case when cpa.CreditDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDeYesterday
	 ,sum(case when cpa.CreditDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.CreditDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeLastMonth
	,sum(case when cpa.CreditDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.CreditDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeLastQuarter
	,sum(case when cpa.CreditDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.CreditDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeLastYear
	,sum(case when cpa.CreditDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeThisMonth
	,sum(case when cpa.CreditDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeThisQuarter
	,sum(case when cpa.CreditDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeThisYear
FROM  [DWH_staging].[fiktivo_AffiliateCommission_Credit] cpa with(nolock)  
INNER JOIN [DWH_staging].[fiktivo_AffiliateCommission_CreditCommission] cc with(nolock) 
ON cpa.CreditID = cc.CreditID 
AND cc.Tier=1 
WHERE  cpa.CreditTypeID=1 AND 
       cpa.Valid = 1 AND 
	   CAST(cpa.IsFirstDeposit as INT) = 1 AND 
	   cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0)
GROUP  BY cpa.AffiliateID --,cpa.CID

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

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_MasterAffiliate]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_MasterAffiliate]
([AffiliateID]
,[MasterAffiliateID])
SELECT a.[NewMemberID] AffiliateID
,a.[AffiliateID] MasterAffiliateID
FROM [DWH_staging].[fiktivo_dbo_tblaff_Tier2Members] a

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_Registrations]
--Alter by Noga 3/11/22

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_Registrations]
([AffiliateID]
,[RegistrationFirstDate]
,[RegistrationLastDate]
,[RegistrationLifeTime]
,[RegistrationYesterday]
,[RegistrationLastMonth]
,[RegistrationLastQuarter]
,[RegistrationLastYear]
,[RegistrationThisMonth]
,[RegistrationThisQuarter]
,[RegistrationThisYear])

SELECT 
	Registrations.AffiliateID
	--,Registrations.CID As Real_CID  ---<<<<< optional, New column
	,min(Registrations.RegistrationDate)  RegistrationFirstDate
	,max(Registrations.RegistrationDate)  RegistrationLastDate
	,Count(Registrations.RegistrationID) AS RegistrationLifeTime
	,sum(case when Registrations.RegistrationDate >= dateadd(day,datediff(day,1,GETDATE()),0) and Registrations.RegistrationDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS RegistrationYesterday
	,sum(case when Registrations.RegistrationDate > EOMONTH(DATEADD(mm,-2,getdate())) and Registrations.RegistrationDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationLastMonth
	,sum(case when Registrations.RegistrationDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and Registrations.RegistrationDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationLastQuarter
	,sum(case when Registrations.RegistrationDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and Registrations.RegistrationDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationLastYear
	,sum(case when Registrations.RegistrationDate >= DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationThisMonth
	,sum(case when Registrations.RegistrationDate >= DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationThisQuarter
	,sum(case when Registrations.RegistrationDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationThisYear
FROM   [DWH_staging].[fiktivo_AffiliateCommission_Registration] Registrations with(nolock) 
INNER JOIN [DWH_staging].[fiktivo_AffiliateCommission_RegistrationCommission] RC 
ON Registrations.RegistrationID = RC.RegistrationID 
AND RC.Tier=1
WHERE Registrations.RegistrationDate < dateadd(day,datediff(day,0,GETDATE()),0)
group by Registrations.AffiliateID --,Registrations.CID

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

EXEC [DWH_dbo].SP_Dim_Affiliate

--------------------
TRUNCATE TABLE [DWH_dbo].[Dim_BonusType]

INSERT INTO [DWH_dbo].[Dim_BonusType]
           ([BonusTypeID]
           ,[Name]
           ,[IsWithdrawable]
           ,[IsActive]
           ,[DWHBonusTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
SELECT BonusTypeID,
	   Name,
	   IsWithdrawable,
	   IsActive,
	   BonusTypeID AS DWHBonusTypeID,
	   1 as StatusID,
	   GETDATE() as UpdateDate,
	   GETDATE() as InsertDate
FROM [DWH_staging].[etoro_BackOffice_BonusType]

--------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_EvMatchStatus]

INSERT INTO [DWH_dbo].[Dim_EvMatchStatus](
[EvMatchStatusID]
,[EvMatchStatusName]
,[UpdateDate]
)
SELECT 
[EvMatchStatusId]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_EvMatchStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ExtendedUserField]

INSERT INTO [DWH_dbo].[Dim_ExtendedUserField]
([FieldID]
,[FieldTypeID]
,[ExtendedUserFieldName]
,[UpdateDate])
SELECT 
[FieldId]
,[FieldTypeId]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_ExtendedUserField]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_VerificationStatus]

INSERT INTO [DWH_dbo].[Dim_VerificationStatus]
([VerificationStatusID]
,[Name]
,[UpdateDate])
SELECT 
[VerificationStatusID]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_VerificationStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_AccountStatus]

INSERT INTO [DWH_dbo].[Dim_AccountStatus]
([AccountStatusID]
,[AccountStatusName]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[AccountStatusID]
,[AccountStatusName]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_AccountStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_AccountType]

INSERT INTO [DWH_dbo].[Dim_AccountType]
([AccountTypeID]
,[Name]
,[DWHAccountTypeID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[AccountTypeID]
,[AccountTypeName]
,[AccountTypeID] as [DWHAccountTypeID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_AccountType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutFeeGroup]

INSERT INTO [DWH_dbo].[Dim_CashoutFeeGroup]
([CashoutFeeGroupID]
,[CashoutFeeGroupName]
,[UpdateDate])
SELECT 
[CashoutFeeGroupID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutFeeGroup]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutStatus]

INSERT INTO [DWH_dbo].[Dim_CashoutStatus]
([CashoutStatusID]
,[Name]
,[DWHCashoutStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[CashoutStatusID]
,[Name]
,[CashoutStatusID] as [DWHCashoutStatusID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutStatus]


TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Channel]

INSERT INTO [DWH_dbo].[Ext_Dim_Channel]
           ([AffiliateID]
           ,[DateCreated]
           ,[MarketingExpenseID]
           ,[MarketingExpenseName]
           ,[Contact]
           ,[AffiliatesGroupsName]
           ,[ContractName]
           ,[Channel]
           ,[newContact])
select a.AffiliateID
,a.DateCreated
,a.MarketingExpenseID 
,b.MarketingExpenseName 
,a.Contact 
,c.AffiliatesGroupsName 
,[Description] as ContractName
,CASE
WHEN isnull(b.MarketingExpenseName,'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'				
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' 
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE isnull(b.MarketingExpenseName,'Direct')
END AS Channel
,replace(lower(a.Contact) ,'nonbrand','paid') as newContact 
FROM [DWH_staging].[fiktivo_dbo_tblaff_Affiliates] a
left join [DWH_staging].[fiktivo_dbo_tblaff_MarketingExpense] b  on a.MarketingExpenseID=b.MarketingExpenseID
left join [DWH_staging].[fiktivo_dbo_tblaff_AffiliatesGroups] c  on a.AffiliatesGroupsID = c.AffiliatesGroupsID
left join [DWH_staging].[fiktivo_dbo_tblaff_AffiliateTypes] afftype  on a.[AffiliateTypeID]=afftype.[AffiliateTypeID]
----------------------------------------------
Exec [DWH_dbo].[SP_Dim_Channel]

--------

TRUNCATE TABLE [DWH_dbo].[Dim_ClientWithdrawReason]

INSERT INTO [DWH_dbo].[Dim_ClientWithdrawReason]
([ClientWithdrawReasonID]
,[ClientWithdrawReasonName]
,[UpdateDate])
SELECT 
[ClientWithdrawReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ClientWithdrawReason]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ClosePositionReason]

INSERT INTO [DWH_dbo].[Dim_ClosePositionReason]
([ClosePositionReasonID]
,[Name]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[ID]
,[ClosePositionActionName]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ClosePositionActionType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CountryBin]

INSERT INTO [DWH_dbo].[Dim_CountryBin]
([CountryID]
,[BinCode]
,[IssuingBank]
,[CardTypeID]
,[CardSubType]
,[CardCategory]
,[BankWebSite]
,[BankInfo]
,[ShouldCheck3ds]
,[MinAmountFor3ds]
,[IsPrepaid]
,[UpdateDate])
SELECT 
[CountryID]
,[BinCode]
,[IssuingBank]
,[CardTypeID]
,[CardSubType]
,[CardCategory]
,[BankWebSite]
,[BankInfo]
,[ShouldCheck3ds]
,[MinAmountFor3ds]
,[IsPrepaid]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CountryBin]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CountryIP]

INSERT INTO [DWH_dbo].[Dim_CountryIP]
([CountryID]
,[IPFrom]
,[IPTo]
,[RegionID]
,[UpdateDate])
SELECT 
[CountryID]
,[IPFrom]
,[IPTo]
,[RegionID]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CountryIP]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CreditType]

INSERT INTO [DWH_dbo].[Dim_CreditType]
([CreditTypeID]
,[CreditTypeName]
,[UpdateDate])
SELECT 
[CreditTypeID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CreditType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Currency]

INSERT INTO [DWH_dbo].[Dim_Currency]
([CurrencyID]
,[CurrencyTypeID]
,[Name]
,[Abbreviation]
,[Mask]
,[EEAStockExchange]
,[ISINCode]
,[CurrencySymbol]
,[InterestRateID]
,[UpdateDate])
SELECT 
[CurrencyID]
,[CurrencyTypeID]
,[Name]
,[Abbreviation]
,[Mask]
,[EEAStockExchange]
,[ISINCode]
,[CurrencySymbol]
,[InterestRateID]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Currency]


----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_BillingDepot]

INSERT INTO [DWH_dbo].[Dim_BillingDepot]
           ([DepotID]
           ,[FundingTypeID]
           ,[PaymentTypeID]
           ,[ProtocolID]
           ,[Name]
           ,[IsActive]
           ,[UpdateDate])
select 
[DepotID]
,[FundingTypeID]
,[PaymentTypeID]
,[ProtocolID]
,[Name]
,[IsActive]
, getdate() as UpdateDate
 FROM [DWH_staging].[etoro_Billing_Depot]


----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_DocumentStatus]

INSERT INTO [DWH_dbo].[Dim_DocumentStatus]
([DocumentStatusID]
,[DocumentStatusName]
,[UpdateDate])
SELECT 
[DocumentStatusID]
,[DocumentStatusName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_DocumentStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ExchangeInfo]

INSERT INTO [DWH_dbo].[Dim_ExchangeInfo]
([ExchangeID]
,[ExchangeDescription]
,[UpdateDate])
SELECT 
[ExchangeID]
,[ExchangeDescription]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ExchangeInfo]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_FundType]

INSERT INTO [DWH_dbo].[Dim_FundType]
([FundTypeID]
,[FundTypeName]
,[UpdateDate])
SELECT 
[FundTypeID]
,[Description]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_FundType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Fund]

INSERT INTO [DWH_dbo].[Dim_Fund]
           ([FundID]
           ,[FundName]
           ,[FundAccountID]
           ,[FundOwnerID]
           ,[IsPublic]
           ,[MinCopyAmount]
           ,[RefreshIntervalMonths]
           ,[FundType]
           ,[UpdateDate])

SELECT [FundID]
      ,[FundName]
      ,[FundAccountID]
      ,[FundOwnerID]
      ,[IsPublic]
      ,[MinCopyAmount]
      ,[RefreshIntervalMonths]
      ,[FundType]
 ,getdate() as UpdateDate
from 
[DWH_staging].[etoro_Trade_Fund]
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_FundingType]

INSERT INTO [DWH_dbo].[Dim_FundingType]
([FundingTypeID]
,[Name]
,[IsNewStyle]
,[IsSingleFunding]
,[IsCashoutActive]
,[DWHFundingTypeID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[FundingTypeID]
,[Name]
,[IsNewStyle]
,[IsSingleFunding]
,[IsCashoutActive]
,[FundingTypeID] as [DWHFundingTypeID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_FundingType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Funnel]

INSERT INTO [DWH_dbo].[Dim_Funnel]
([FunnelID]
,[Name]
,[PlatformID]
,[UpdateDate]
,[InsertDate]
,[StatusID])
SELECT 
[FunnelID]
,[Name]
,[PlatformID]
,getdate()
,getdate()
,1 as StatusID
FROM [DWH_staging].[etoro_Dictionary_Funnel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_GuruStatus]

INSERT INTO [DWH_dbo].[Dim_GuruStatus]
([GuruStatusID]
,[GuruStatusName]
,[UpdateDate])
SELECT 
[GuruStatusID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_GuruStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Label]

INSERT INTO [DWH_dbo].[Dim_Label]
([LabelID]
,[Name]
,[DWHLabelID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[LabelID]
,[Name]
,[LabelID] as[DWHLabelID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Label]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Language]

INSERT INTO [DWH_dbo].[Dim_Language]
([LanguageID]
,[Name]
,[DWHLanguageID]
,[StatusID]
,[UpdateDate]
,[InsertDate]
,[IsoCode]
,[CultureCode])
SELECT 
[LanguageID]
,[Name]
,[LanguageID] as [DWHLanguageID]
,1 as StatusID
,getdate()
,getdate()
,[IsoCode]
,[CultureCode]
FROM [DWH_staging].[etoro_Dictionary_Language]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Manager]

INSERT INTO [DWH_dbo].[Ext_Dim_Manager]
           ([ManagerID]
           ,[UserGroup]
           ,[ParentUserGroup]
           ,[FirstName]
           ,[LastName]
           ,[IsActive]
           ,[IsTeamLeader]
           ,[DWHManagerID]
           ,[StatusID]
           ,[CalendlyID])
select ManagerID,'Not Available' as UserGroup,'Not Available' as ParentUserGroup,FirstName,LastName,IsActive,IsTeamLeader, 
ManagerID as DWHManagerID, 1 as StatusID
,CalendlyID
from [DWH_staging].[etoro_BackOffice_Manager]

UPDATE 
 A 
SET FirstName=B.FirstName,
 LastName=B.LastName,
 IsTeamLeader=B.IsTeamLeader,
 IsActive=B.IsActive,
CalendlyID = B.CalendlyID,
 UpdateDate=GETDATE()
FROM 
 [DWH_dbo].[Dim_Manager] A
 INNER JOIN
[DWH_dbo].[Ext_Dim_Manager] B
 ON A.ManagerID=B.ManagerID

 INSERT INTO  [DWH_dbo].[Dim_Manager]
 (ManagerID,UserGroup,ParentUserGroup,FirstName,
 LastName,IsActive,IsTeamLeader,DWHManagerID,
 UpdateDate,InsertDate,StatusID,CalendlyID)
SELECT b.ManagerID,
b.UserGroup,
b.ParentUserGroup,
b.FirstName,
b.LastName,
b.IsActive,
b.IsTeamLeader,
b.ManagerID,
GETDATE() as UpdateDate,
GETDATE() as InsertDate,
1 as StatusID,
b.CalendlyID
FROM  [DWH_dbo].[Dim_Manager] a
right JOIN 
 [DWH_dbo].[Ext_Dim_Manager] b
ON(a.ManagerID=b.ManagerID)
WHERE a.ManagerID IS null

update DWH_dbo.Dim_Manager
set 
[SFManagerID] = b.[SFManagerID]
from DWH_dbo.Dim_Manager a
join [DWH_staging].[SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping] b
on a.ManagerID = b.[ManagerID]
where a.ManagerID not in (0,1)
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_MifidCategorization]

INSERT INTO [DWH_dbo].[Dim_MifidCategorization]
([MifidCategorizationID]
,[Name]
,[UpdateDate])
SELECT 
[MifidCategorizationID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_MifidCategorization]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_MirrorType]

INSERT INTO [DWH_dbo].[Dim_MirrorType]
([MirrorTypeID]
,[MirrorTypeName]
,[UpdateDate])
SELECT 
[MirrorTypeID]
,[MirrorTypeName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_MirrorType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PaymentStatus]

INSERT INTO [DWH_dbo].[Dim_PaymentStatus]
([PaymentStatusID]
,[Name]
,[DWHPaymentStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT
[PaymentStatusID]
,[Name]
,[PaymentStatusID] as [DWHPaymentStatusID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PaymentStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PendingClosureStatus]

INSERT INTO [DWH_dbo].[Dim_PendingClosureStatus]
([PendingClosureStatusID]
,[PendingClosureStatusName]
,[UpdateDate])
SELECT 
[PendingClosureStatusID]
,[PendingClosureStatusName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PendingClosureStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PhoneVerified]

INSERT INTO [DWH_dbo].[Dim_PhoneVerified]
([PhoneVerifiedID]
,[PhoneVerifiedName]
,[UpdateDate])
SELECT 
[PhoneVerifiedID]
,[PhoneVerifiedName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PhoneVerified]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Platform]

INSERT INTO [DWH_dbo].[Dim_Platform]
([PlatformID]
,[Platform]
,[UpdateDate])
SELECT 
[Id]
,[Platform]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Platform]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerLevel]

INSERT INTO [DWH_dbo].[Dim_PlayerLevel]
([PlayerLevelID]
,[Name]
,[CashoutPendingHours]
,[FromSumLotCount]
,[ToSumLotCount]
,[FromSumDeposit]
,[ToSumDeposit]
,[Sort]
,[DWHPlayerLevelID]
,[UpdateDate]
,[InsertDate]
,[StatusID])
SELECT 
[PlayerLevelID]
,[Name]
,[CashoutPendingHours]
,[FromSumLotCount]
,[ToSumLotCount]
,[FromSumDeposit]
,[ToSumDeposit]
,[Sort]
, [PlayerLevelID] as  [DWHPlayerLevelID]
,getdate()
,getdate()
,1 as [StatusID]
FROM [DWH_staging].[etoro_Dictionary_PlayerLevel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatus]

INSERT INTO [DWH_dbo].[Dim_PlayerStatus]
([PlayerStatusID]
,[Name]
,[IsBlocked]
,[CanEditPosition]
,[CanOpenPosition]
,[CanClosePosition]
,[CanDeposit]
,[CanRequestWithdraw]
,[CanLogin]
,[CanChatAndPost]
,[CanBeCopied]
,[DWHPlayerStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[PlayerStatusID]
,[Name]
,[IsBlocked]
,[CanEditPosition]
,[CanOpenPosition]
,[CanClosePosition]
,[CanDeposit]
,[CanRequestWithdraw]
,[CanLogin]
,[CanChatAndPost]
,[CanBeCopied]
,[PlayerStatusID] as [DWHPlayerStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatusReasons]

INSERT INTO [DWH_dbo].[Dim_PlayerStatusReasons]
([PlayerStatusReasonID]
,[Name]
,[UpdateDate])
SELECT 
[PlayerStatusReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatusReasons]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatusSubReasons]

INSERT INTO [DWH_dbo].[Dim_PlayerStatusSubReasons]
([PlayerStatusSubReasonID]
,[PlayerStatusSubReasonName]
,[UpdateDate])
SELECT 
[PlayerStatusSubReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatusSubReasons]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RedeemReason]

INSERT INTO [DWH_dbo].[Dim_RedeemReason]
([RedeemReasonID]
,[RedeemReasonName]
,[UpdateDate])
SELECT 
[RedeemReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RedeemReason]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RedeemStatus]

INSERT INTO [DWH_dbo].[Dim_RedeemStatus]
([RedeemStatusID]
,[Name]
,[DisplayName]
,[IsCancelable]
,[InsertDate]
,[UpdateDate])
SELECT 
[RedeemStatusID]
,[Name]
,[DisplayName]
,[IsCancelable]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RedeemStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]

INSERT INTO [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
           ([ProtocolMIDSettingsID]
           ,[ParameterID]
           ,[DepotID]
           ,[DepotModeID]
           ,[Value]
           ,[RegulationID]
           ,[CurrencyID]
           ,[Description]
           ,[SubTypeID]
           ,[MerchantAccountID]
           ,[UpdateDate])
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
GETDATE() AS UpdateDate
FROM [DWH_staging].[etoro_Billing_ProtocolMIDSettings]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Campaign]

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
--      ,[IsActive]
--      ,[ParticipatedUsers]
--      ,[Description]
--      ,GETDATE() as InsertDate
--      ,GETDATE() as UpdateDate
--  FROM [DWH_staging].[etoro_BackOffice_Campaign]

-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutMode]

INSERT INTO [DWH_dbo].[Dim_CashoutMode]
           ([CashoutModeID]
           ,[CashoutModeName]
           ,[CashoutModeWeight]
           ,[UpdateDate])
SELECT [CashoutModeID]
      ,[CashoutModeName]
      ,[CashoutModeWeight]
	  ,getdate()
  FROM [DWH_staging].[etoro_Dictionary_CashoutMode]

-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutReason]

INSERT INTO [DWH_dbo].[Dim_CashoutReason]
([CashoutReasonID]
,[Name]
,[UpdateDate])
SELECT [CashoutReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutReason]


-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_State_and_Province]

INSERT INTO [DWH_dbo].[Dim_State_and_Province]
           ([RegionByIP_ID]
           ,[CountryID]
           ,[ShortName]
           ,[Name]
           ,[UpdateDate])
select 
rei.RegionByIP_ID,
ren.CountryID,
ren.ShortName,
ren.Name,
getdate() as UpdateDate
from [DWH_staging].[etoro_Dictionary_RegionByIP] as rei 
Join [DWH_staging].[etoro_Dictionary_RegionName] as ren
On rei.Name = ren.ShortName  and rei.CountryID=ren.CountryID

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
TRUNCATE TABLE [DWH_dbo].[Dim_Regulation]

INSERT INTO [DWH_dbo].[Dim_Regulation]
([ID]
,[Name]
,[DWHRegulationID]
,[StatusID]
,[UpdateDate]
,[InsertDate]
,[ClusterRegulationID])
SELECT 
[ID]
,[Name]
,[ID] as [DWHRegulationID]
,1 as [StatusID]
,getdate()
,getdate()
,CASE WHEN ID in (0,1,5) THEN 1 ELSE ID END as ClusterRegulationID
FROM [DWH_staging].[etoro_Dictionary_Regulation]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskClassification]

INSERT INTO [DWH_dbo].[Dim_RiskClassification]
([RiskClassificationID]
,[RiskClassificationName]
,[RiskScore]
,[UpdateDate])
SELECT 
[RiskClassificationID]
,[Name]
,[RiskScore]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskClassification]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskManagementStatus]

INSERT INTO [DWH_dbo].[Dim_RiskManagementStatus]
([RiskManagementStatusID]
,[Name]
,[DWHRiskManagementStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[RiskManagementStatusID]
,[Name]
, [RiskManagementStatusID] as [DWHRiskManagementStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskManagementStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskStatus]

INSERT INTO [DWH_dbo].[Dim_RiskStatus]
([RiskStatusID]
,[Name]
,[IsActive]
,[DWHRiskStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[RiskStatusID]
,[Name]
,[IsActive]
,[RiskStatusID] as [DWHRiskStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskStatus]
   
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ThreeDsResponseTypes]

INSERT INTO [DWH_dbo].[Dim_ThreeDsResponseTypes]
([ThreeDsResponseTypeID]
,[ThreeDsResponseTypesName]
,[UpdateDate])
SELECT 
[ThreeDsResponseTypeID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ThreeDsResponseTypes]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_VerificationLevel]

INSERT INTO [DWH_dbo].[Dim_VerificationLevel]
([ID]
,[Name]
,[DWHVerificationLevelID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[ID]
,[Name]
,[ID] as [DWHVerificationLevelID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_VerificationLevel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_WorldCheck]

INSERT INTO [DWH_dbo].[Dim_WorldCheck]
([WorldCheckID]
,[WorldCheckName]
,[UpdateDate])
SELECT 
[WorldCheckID]
,[WorldCheckName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_WorldCheck]


--------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CompensationReason]

INSERT INTO [DWH_dbo].[Dim_CompensationReason]
	  ([CompensationReasonID]
      ,[ParentID]
      ,[Name]
	  ,[DWHCompensationID]
	  ,[StatusID]
	  ,[UpdateDate]
	  ,[InsertDate])
SELECT [CompensationReasonID]
      ,[ParentID]
      ,[Name]
      ,[CompensationReasonID]
	  ,1
	  ,getdate()
	  ,getdate()
  FROM [DWH_staging].[etoro_BackOffice_CompensationReason]

TRUNCATE TABLE [DWH_dbo].[Dim_ScreeningStatus]

INSERT INTO [DWH_dbo].[Dim_ScreeningStatus]
           ([ScreeningStatusID]
           ,[Name]
           ,[UpdateDate])
SELECT [ID]
      ,[Name]
	  ,getdate()
  FROM [DWH_staging].[ScreeningService_Dictionary_ScreeningStatus]


----------------------------------HistoryCosts-----------------------------------------
TRUNCATE TABLE [DWH_dbo].[Dim_CalculationType]

INSERT INTO [DWH_dbo].[Dim_CalculationType](
[CalculationTypeId],
[CalculationType],
[UpdateDate])
SELECT 
[Id],
[CalculationType],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CalculationType]

TRUNCATE TABLE [DWH_dbo].[Dim_CostConfigurationId]

INSERT INTO [DWH_dbo].[Dim_CostConfigurationId](
[CostConfigurationId],
[CostConfiguration],
[UpdateDate])
SELECT 
[Id],
[CostConfigurationId],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostConfigurationId]

TRUNCATE TABLE [DWH_dbo].[Dim_CostSubtype]

INSERT INTO [DWH_dbo].[Dim_CostSubtype](
[CostSubtypeId],
[CostSubtype],
[UpdateDate])
SELECT 
[Id],
[CostSubtype],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostSubtype]


TRUNCATE TABLE [DWH_dbo].[Dim_CostType]

INSERT INTO [DWH_dbo].[Dim_CostType](
[CostTypeId],
[CostType],
[UpdateDate])
SELECT 
[Id],
[CostType],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostType]

TRUNCATE TABLE [DWH_dbo].[Dim_ExecutionOperationType]

INSERT INTO [DWH_dbo].[Dim_ExecutionOperationType](
[OperationTypeId],
[OperationType],
[UpdateDate])
SELECT 
[Id],
[OperationType],
getdate()
FROM [DWH_staging].HistoryCosts_Dictionary_ExecutionOperationType

INSERT INTO [DWH_dbo].[Dim_FeeOperationTypes](
[FeeOperationTypeID],
[FeeOperationTypeName],
[UpdateDate])
SELECT 
[FeeOperationTypeID],
[Name],
getdate()
FROM [DWH_staging].etoro_Dictionary_FeeOperationTypes
---------------------------------------------------------------------------

---- iNSERT DEFAULT VALUES 0
DECLARE @ddate date = cast(getdate() as date)

INSERT INTO [DWH_dbo].[Dim_AccountStatus]
           ([AccountStatusID]
           ,[AccountStatusName]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
           ,'N/A'
           ,1
           ,@ddate
           ,@ddate
		   )
---------------------

INSERT INTO [DWH_dbo].[Dim_AccountType]
           ([AccountTypeID]
           ,[Name]
           ,[DWHAccountTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

-------------


INSERT INTO [DWH_dbo].[Dim_BonusType]
           ([BonusTypeID]
           ,[Name]
           ,[IsWithdrawable]
           ,[IsActive]
           ,[DWHBonusTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

----------------


INSERT INTO [DWH_dbo].[Dim_FundingType]
           ([FundingTypeID]
           ,[Name]
           ,[IsNewStyle]
           ,[IsSingleFunding]
           ,[IsCashoutActive]
           ,[DWHFundingTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )
-------------

INSERT INTO [DWH_dbo].[Dim_Language]
           ([LanguageID]
           ,[Name]
           ,[DWHLanguageID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate]
           ,[IsoCode]
           ,[CultureCode])
     VALUES
          (0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   ,'N/A'
		   ,'N/A'
		   )

 --------------
INSERT INTO [DWH_dbo].[Dim_PaymentStatus]
           ([PaymentStatusID]
           ,[Name]
           ,[DWHPaymentStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
	VALUES
			(-1
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

 --------------


INSERT INTO [DWH_dbo].[Dim_PlayerLevel]
           ([PlayerLevelID]
           ,[Name]
           ,[CashoutPendingHours]
           ,[FromSumLotCount]
           ,[ToSumLotCount]
           ,[FromSumDeposit]
           ,[ToSumDeposit]
           ,[Sort]
           ,[DWHPlayerLevelID]
           ,[UpdateDate]
           ,[InsertDate]
           ,[StatusID])
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
           ,@ddate
           ,@ddate
		   ,1
		   )

---------------

INSERT INTO [DWH_dbo].[Dim_PlayerStatus]
           ([PlayerStatusID]
           ,[Name]
           ,[IsBlocked]
           ,[CanEditPosition]
           ,[CanOpenPosition]
           ,[CanClosePosition]
           ,[CanDeposit]
           ,[CanRequestWithdraw]
           ,[CanLogin]
           ,[CanChatAndPost]
           ,[CanBeCopied]
           ,[DWHPlayerStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
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
           ,@ddate
           ,@ddate
		   )
-------------


INSERT INTO [DWH_dbo].[Dim_RedeemStatus]
           ([RedeemStatusID]
           ,[Name]
           ,[DisplayName]
           ,[IsCancelable]
           ,[InsertDate]
           ,[UpdateDate])
	VALUES
		   (0
           ,'N/A'
		   ,'N/A'
           ,1
           ,@ddate
           ,@ddate
		   )

-----


INSERT INTO [DWH_dbo].[Dim_RiskManagementStatus]
           ([RiskManagementStatusID]
           ,[Name]
           ,[DWHRiskManagementStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
			(0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

-------


INSERT INTO [DWH_dbo].[Dim_CompensationReason]
           ([CompensationReasonID]
           ,[ParentID]
           ,[Name]
           ,[DWHCompensationID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
		   ,Null
           ,'N/A'
		   ,0
		   ,1
           ,@ddate
		   ,@ddate
		   )


-----------------

INSERT INTO [DWH_dbo].[Dim_CashoutStatus]
           ([CashoutStatusID]
           ,[Name]
           ,[DWHCashoutStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
			(0
           ,'N/A'
		   ,0
		   ,1
           ,@ddate
		   ,@ddate
		   )


-------------------


INSERT INTO [DWH_dbo].[Dim_Campaign]
           ([CampaignID]
           ,[CampaignGroupID]
           ,[Code]
           ,[MaxNumberOfUsers]
           ,[StartDate]
           ,[EndDate]
           ,[MaxBonusAmount]
           ,[IsActive]
           ,[ParticipatedUsers]
           ,[Description]
           ,[InsertDate]
           ,[UpdateDate])
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
           ,@ddate
		   ,@ddate
		   )

------------------

INSERT INTO [DWH_dbo].[Dim_VerificationLevel]
           ([ID]
           ,[Name]
           ,[DWHVerificationLevelID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (-1
           ,'N/A'
		   ,-1
		   ,1
           ,@ddate
		   ,@ddate
		   )

--------------------------
DECLARE @MaxFullDate DATE 
DECLARE @StartDate DATE 
DECLARE @EndDate DATE
SELECT  @MaxFullDate = max(FullDate) FROM  [DWH_dbo].[Dim_Date]


IF DATEDIFF(YEAR,GETDATE(),@MaxFullDate)<=1
BEGIN
	SELECT @StartDate =  DATEADD(DAY,1,@MaxFullDate)
	SELECT  @EndDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY,365,@StartDate)) + 1, -1) 
	EXEC [DWH_dbo].[SP_PopulateDimDate] @StartDate,@EndDate
END 





  END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype | `—` |
| `HistoryCosts.Dictionary.ExecutionOperationType` | unresolved | Dictionary | ExecutionOperationType | `—` |
| `DWH_dbo.SP_Dictionaries_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Dictionaries_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dictionaries_DL_To_Synapse.sql` |
