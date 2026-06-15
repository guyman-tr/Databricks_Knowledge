USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Affiliate(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

/********************************************************************************************
Author:      Boris Slutski
Date:        2019-01-13
Description: Update table Dim_Affiliate
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2019-03-11      Boris Slutski	Add new Extracts 
2021-05-02      Chen Avraham    Update SubChannels classification logic. Add 'SubChannel' & 'Channel' columns.
2022-03-27      Jan Iablunovskey  New channels created :Media Programmatic,Media Performance,Content Partnerships,TV,Social Organic
2022-11-22     Adi Ferber		update subchannel script semandad by Eti Rozilio
2023-02-15     Adi Ferber       reffer script to use subchannel unifycode and Ext_Dim_Channel_UnifyCode
*********************************************************************************************/

TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Affiliate

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Affiliate
           (`AffiliateID`
           ,`DateCreated`
           ,`SubChannelID`
		   ,`SubChannel`
		   ,`Channel`
           ,`Contact`
           ,`ContractName`
           ,`ContractType`
		   ,LanguageName
           ,`AffiliatesGroupsName`
           ,`AccountActivated`
           ,`LoginName`
           ,`TradingAccount_RealCID`
           ,`TradingAccount_UserName`
           ,`Email`
           ,`CompanyAddress`
           ,`City`
           ,`CountryID`
           ,`WebSiteURL`
           ,`RegistrationFirstDate`
           ,`RegistrationLastDate`
           ,`RegistrationLifeTime`
           ,`RegistrationYesterday`
           ,`RegistrationLastMonth`
           ,`RegistrationLastQuarter`
           ,`RegistrationLastYear`
		   ,RegistrationThisMonth
		   ,RegistrationThisQuarter
		   ,RegistrationThisYear
           ,`FTDFirstDate`
           ,`FTDLastDate`
           ,`FTDLifeTime`
           ,`FTDYesterday`
           ,`FTDLastMonth`
           ,`FTDLastQuarter`
           ,`FTDLastYear`
		   ,FTDThisMonth
		   ,FTDThisQuarter
		   ,FTDThisYear
           ,`FTDeFirstDate`
           ,`FTDeLastDate`
           ,`FTDeLifeTime`
           ,`FTDeYesterday`
           ,`FTDeLastMonth`
           ,`FTDeLastQuarter`
           ,`FTDeLastYear`
		   ,FTDeThisMonth
		   ,FTDeThisQuarter
		   ,FTDeThisYear
           ,`MasterAffiliateID`
		   ,WebSiteTitle
		   ,GCID
		   ,EntityName
		   ,ContactPersonFullName
	       ,Telephone
           ,`UpdateDate`)

SELECT
	 t.AffiliateID
	,sub.DateCreated  
	,sub.SubChannelID
	,sub.SubChannel
	,sub.Channel
	,Contact
	,ContractName
	,COALESCE(CASE WHEN t .AffiliateID IN (12306, 14596, 30122, 37665, 18230) THEN 6
WHEN LOWER(ContractName) LIKE '%internal campaigns%' THEN 6 /*--eCost*/
WHEN LOWER(ContractName) LIKE '%rev%' AND LOWER(ContractName) LIKE '%cpa%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rs%' AND LOWER(ContractName) LIKE '%cpa%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rev%' AND LOWER(ContractName) LIKE '%cpl%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rs%' AND LOWER(ContractName) LIKE '%cpl%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rev%' AND LOWER(ContractName) LIKE '%cpr%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rs%' AND LOWER(ContractName) LIKE '%cpr%' THEN 4 --Hyb
WHEN LOWER(ContractName) LIKE '%rev%' THEN 3 --Rev
WHEN LOWER(ContractName) LIKE '%rs%' THEN 3 --Rev
WHEN LOWER(ContractName) LIKE '%cpa%' THEN 2 --CPA
WHEN LOWER(ContractName) LIKE '%plan%' THEN 2 --CPA
WHEN LOWER(ContractName) LIKE '%mati%' AND LOWER(ContractName) LIKE '%cpl%' THEN 8--CPL
WHEN LOWER(ContractName) LIKE '%mati%' AND LOWER(ContractName) LIKE '%%%' THEN 3 --Rev
WHEN LOWER(ContractName) LIKE '%cpl%' THEN  8 --'CPL'
WHEN LOWER(ContractName) LIKE '%cpr%' THEN 8--'CPR'
WHEN t .Channel = 'Affiliate' AND LOWER(ContractName) LIKE '%0 commission%' THEN 7
ELSE 0 
END, 0) AS ContractType  --N/A as other
	,LanguageName
	,AffiliatesGroupsName
	,AccountActivated
	,LoginName
	,COALESCE(BO1.CID, BO2.CID, BO3.CID, BO4.CID) TradingAccount_RealCID
	,COALESCE(BO1.UserName, BO2.UserName, BO3.UserName, BO4.UserName) as TradingAccount_UserName
	,t.Email
	,t.CompanyAddress
	,t.City
	,t.CountryID
	,t.WebSiteURL
	,RegistrationFirstDate
	,RegistrationLastDate
	,RegistrationLifeTime
	,RegistrationYesterday
	,RegistrationLastMonth
	,RegistrationLastQuarter
	,RegistrationLastYear
	,RegistrationThisMonth
	,RegistrationThisQuarter
	,RegistrationThisYear
	,FTDFirstDate
	,FTDLastDate
	,FTDLifeTime
	,FTDYesterday
	,FTDLastMonth
	,FTDLastQuarter
	,FTDLastYear
	,FTDThisMonth
	,FTDThisQuarter
	,FTDThisYear
	,FTDeFirstDate
	,FTDeLastDate
	,FTDeLifeTime
	,FTDeYesterday
	,FTDeLastMonth
	,FTDeLastQuarter
	,FTDeLastYear
	,FTDeThisMonth
	,FTDeThisQuarter
	,FTDeThisYear
	,MasterAffiliateID
	,WebSiteTitle
	,GCID
	,EntityName
	,ContactPersonFullName
	,Telephone
	,current_timestamp() AS UpdateDate
FROM    dwh_daily_process.migration_tables.Ext_Dim_Channel_Affiliate_UnifyCode t 
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_SubChannel_UnifyCode AS sub 	    ON sub.AffiliateID  = t.AffiliateID
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer BO1 			ON BO1.UserName  = t.UserName1 
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer BO2 			ON BO2.UserName  = t.UserName2 
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer BO3 			ON BO3.UserName  = t.UserName3  
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Customer BO4 			ON BO4.UserName  = t.UserName4  
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_Registrations r 		ON t.AffiliateID = r.AffiliateID
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTD f 				ON t.AffiliateID = f.AffiliateID
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_FTDe fe 				ON t.AffiliateID = fe.AffiliateID
LEFT OUTER JOIN dwh_daily_process.migration_tables.Ext_Dim_Affiliate_MasterAffiliate ma 	ON t.AffiliateID = ma.AffiliateID
;
END;
