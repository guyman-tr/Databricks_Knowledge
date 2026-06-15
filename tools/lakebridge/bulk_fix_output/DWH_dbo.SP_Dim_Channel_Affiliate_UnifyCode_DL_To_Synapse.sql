USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

/********************************************************************************************
Author:      Adi Ferber
Date:        2023-02-15
Description: create one ext tables for channel and affilate data 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

2023-02-28      Adi Ferber    add new subchannel 50 Google Discovery
2023-11-07		Nitsan Sharabi change Media CPA from sub channel to channel 
2023-11-07		Nitsan Sharabi add TikTok 
2023-12-18		Nitsan Sharabi change Media CPA chaneel definition
2023-12-25		Nitsan Sharabi comment "b.MarketingExpenseName = 'Media Performance'..."
2024-10-08      Eti            added channel affiliate branding - subchannel 52


*********************************************************************************************/

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Channel_Affiliate_UnifyCode  --TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Channel_UnifyCode] new ext name need to create new schema  ???
;
INSERT INTO  dwh_daily_process.migration_tables.Ext_Dim_Channel_Affiliate_UnifyCode
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



SELECT							
 a.AffiliateID
,a.DateCreated 
,a.MarketingExpenseID
,b.MarketingExpenseName 
,case when a.Contact is null or a.Contact =' '  then COALESCE(a.EntityName , a.Contact) else a.Contact end AS Contact
,c.AffiliatesGroupsName
,afftype.Description AS ContractName
,CASE
WHEN COALESCE(b.MarketingExpenseName, 'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
--WHEN b.MarketingExpenseName = 'Media Performance' AND [Description]<>'$0 commission (ftde) + 2nd Tier 0% (new)'	THEN 'Media CPA' -- Nitsan 20231025
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
left join dwh_daily_process.daily_snapshot.fiktivo_dbo_tblaff_Languages lan on lan.LanguageID = a.CommunicationLangID;



-----------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_SubChannel_UnifyCode

;
INSERT INTO  dwh_daily_process.migration_tables.Ext_Dim_SubChannel_UnifyCode
(`AffiliateID`
,`DateCreated`
,SubChannelID
,SubChannel
,Channel
,UpdateDate)

SELECT
	t.AffiliateID
	,DateCreated  

	,CASE
		WHEN t.Channel = 'Affiliate'																		THEN 31 --'Affiliate'
		WHEN t.Channel = 'Introducing Agents'																THEN 20 --'IBs'
		WHEN t.AffiliateID IN (56662,56663)																	THEN 1 --'Direct Mobile'
		WHEN t.Channel = 'Direct' AND t.AffiliatesGroupsName = 'Mobile'										THEN 1 --'Direct Mobile'
		WHEN t.Channel = 'Direct' AND t.MarketingExpenseName = 'SMM'										THEN 18 --'SMM'
		WHEN t.Channel = 'Direct'																			THEN 19 --'Direct'
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE 'sem.facebook%'								THEN 32 --'FB'
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE '%taboola%'									THEN 33 --'Taboola'																										
		WHEN t.Channel = 'SEM' AND 	(LOWER(t.`newContact`) LIKE 'sem.twitter%'
								  OR LOWER(t.`newContact`) = 'twitter posts')	         					THEN 34 --'Twitter'																										
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE '%outbrain%'									THEN 35 --'Outbrain'		
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE 'sem.appstore%'								THEN 36 --'ASA'
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE '%.gdn.%'									THEN 11 --'SEM Other'																											
		WHEN t.Channel = 'SEM' AND (LOWER(t.`newContact`) LIKE 'sem.bing%' 									
								  OR LOWER(t.`newContact`) LIKE 'sem.microsoft.bing%')						THEN 37 --'Bing Search'		
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE 'sem.google.desktop.appinstalls%'			THEN 38 --'Google UAC'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND (LOWER(t.`newContact`) LIKE '%.youtube%' OR
									LOWER(t.`newContact`) LIKE '%.yt%')										THEN 22 --'YT'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND (LOWER(t.`newContact`) LIKE '%google.desktop.brand%' 
								 OR LOWER(t.`newContact`) LIKE '%mobile.brand%'
								 OR LOWER(t.`newContact`) LIKE '%google.brand%')							THEN 4 --'Google Brand'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND LOWER(t.`newContact`) LIKE '%google%'
							   AND (LOWER(t.`newContact`) LIKE '%search%' OR
									LOWER(t.`newContact`) LIKE '%nonbrand%' OR
									LOWER(t.`newContact`) LIKE '%paid%')									THEN 5 --'Google Search'
		WHEN t.Channel = 'SEM'	AND LOWER(t.`newContact`) = 'discoveryads'						    		THEN 50 --'Google Discovery'
		WHEN t.Channel = 'SEM'	AND LOWER(t.`newContact`) LIKE '%ik%ok%'									THEN 51 -- 'TikTok'
		WHEN t.Channel = 'SEM'																				THEN 11 --'SEM Other'
		WHEN t.Channel = 'SEO'																				THEN 21 --'SEO'
		WHEN t.Channel = 'Mobile Acquisition' AND t.AffiliatesGroupsName = 'Non-CPA'						THEN 39 --'Mobile Non-CPA'
		WHEN t.Channel = 'Mobile Acquisition'																THEN 40 --'Mobile CPA'
		WHEN t.Channel = 'Media Programmatic'                                           				    THEN 41 --'Media Programmatic'
		WHEN t.Channel = 'Media CPA' /**AND t.ContractName<>'$0 commission (ftde) + 2nd Tier 0% (new)'**/ 	THEN 45 --'Media CPA'
		WHEN t.Channel = 'Media Performance'  /**AND t.ContractName='$0 commission (ftde) + 2nd Tier 0% (new)'**/ THEN 42 --'Media Performance'
		WHEN t.Channel = 'Content Partnerships'                                                             THEN 44 --'Content Partnerships'
		WHEN t.Channel = 'TV'                                           				                    THEN 48 --'TV'
		WHEN t.Channel = 'Social Organic'                                                                   THEN 49 --'Social Organic'
		WHEN t.Channel = 'Friend Referral'																	THEN 43 --'Friend Referral'
		WHEN t.Channel = 'Sponsorships'																		THEN 27 --'Sponsorships'
		WHEN t.Channel = 'systems'																			THEN 28 --'systems'
		WHEN t.Channel = 'OOH'																				THEN 26 --'OOH'
		WHEN t.Channel = 'PR'																				THEN 24 --'PR'
		WHEN t.Channel = 'Productions'																		THEN 30 --'Productions'
		WHEN t.Channel = 'Events'																			THEN 25 --'Events'
		WHEN t.Channel = 'Club'																				THEN 29 --'Club'	
		WHEN t.Channel = 'Affiliate Branding'                                                               THEN 52 --'Affiliate Branding'
		ELSE 0 --'Unknown'	
		END AS SubChannelID

	,CASE
		WHEN t.Channel = 'Affiliate'																		THEN 'Affiliate'
		WHEN t.Channel = 'Introducing Agents'																THEN 'IBs'
		WHEN t.AffiliateID IN (56662,56663)																	THEN 'Direct Mobile'
		WHEN t.Channel = 'Direct' AND t.AffiliatesGroupsName = 'Mobile'										THEN 'Direct Mobile'
		WHEN t.Channel = 'Direct' AND t.MarketingExpenseName = 'SMM'										THEN 'SMM'
		WHEN t.Channel = 'Direct'																			THEN 'Direct'
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE 'sem.facebook%'								THEN 'FB'
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE '%taboola%'									THEN 'Taboola'																									
		WHEN t.Channel = 'SEM' AND 	(LOWER(t.`newContact`) LIKE 'sem.twitter%'
								  OR LOWER(t.`newContact`) = 'twitter posts')	         					THEN 'Twitter'																								
		WHEN t.Channel = 'SEM' AND 	LOWER(t.`newContact`) LIKE '%outbrain%'									THEN 'Outbrain'
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE 'sem.appstore%'								THEN 'ASA'
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE '%.gdn.%'									THEN 'SEM Other'																								
		WHEN t.Channel = 'SEM' AND (LOWER(t.`newContact`) LIKE 'sem.bing%' 									
								  OR LOWER(t.`newContact`) LIKE 'sem.microsoft.bing%')						THEN 'Bing Search'
		WHEN t.Channel = 'SEM' AND  LOWER(t.`newContact`) LIKE 'sem.google.desktop.appinstalls%'			THEN 'Google UAC'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND (LOWER(t.`newContact`) LIKE '%.youtube%' OR
									LOWER(t.`newContact`) LIKE '%.yt%')										THEN 'YT'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND (LOWER(t.`newContact`) LIKE '%google.desktop.brand%' 
								 OR LOWER(t.`newContact`) LIKE '%mobile.brand%'
								 OR LOWER(t.`newContact`) LIKE '%google.brand%')							THEN 'Google Brand'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE 'sem.%'
							   AND LOWER(t.`newContact`) LIKE '%google%'
							   AND (LOWER(t.`newContact`) LIKE '%search%' OR
									LOWER(t.`newContact`) LIKE '%nonbrand%' OR
									LOWER(t.`newContact`) LIKE '%paid%')									THEN 'Google Search'  
		WHEN t.Channel = 'SEM'	AND LOWER(t.`newContact`) = 'discoveryads'						    		THEN 'Discovery'
		WHEN t.Channel = 'SEM' AND LOWER(t.`newContact`) LIKE '%ik%ok%'										THEN 'TikTok'
		WHEN t.Channel = 'SEM'																				THEN 'SEM Other'
		WHEN t.Channel = 'SEO'																				THEN 'SEO'
		WHEN t.Channel = 'Mobile Acquisition' AND t.AffiliatesGroupsName = 'Non-CPA'						THEN 'Mobile Non-CPA'
		WHEN t.Channel = 'Mobile Acquisition'																THEN 'Mobile CPA'
		WHEN t.Channel = 'Media Programmatic'                                                    		    THEN 'Media Programmatic'
		WHEN t.Channel = 'Media CPA' /** AND t.ContractName<>'$0 commission (ftde) + 2nd Tier 0% (new)'**/ 	THEN 'Media CPA'
		WHEN t.Channel = 'Media Performance' /**AND t.ContractName='$0 commission (ftde) + 2nd Tier 0% (new)'**/ 	THEN 'Media Performance'
		WHEN t.Channel = 'Content Partnerships'																THEN 'Content Partnerships'
		WHEN t.Channel = 'TV'                                                    		                    THEN 'TV'
		WHEN t.Channel = 'Social Organic'																    THEN 'Social Organic'
		WHEN t.Channel = 'Friend Referral'																	THEN 'Friend Referral'
		WHEN t.Channel = 'Sponsorships'																		THEN 'Sponsorships'
		WHEN t.Channel = 'systems'																			THEN 'systems'
		WHEN t.Channel = 'OOH'																				THEN 'OOH'
		WHEN t.Channel = 'PR'																				THEN 'PR'
		WHEN t.Channel = 'Productions'																		THEN 'Productions'
		WHEN t.Channel = 'Events'																			THEN 'Events'
		WHEN t.Channel = 'Club'																				THEN 'Club'
		WHEN t.Channel = 'Affiliate Branding'                                                               THEN 'Affiliate Branding'
		ELSE 'Unknown'	
		END AS SubChannel
   
	,CASE WHEN t.Channel = 'Introducing Agents' THEN 'Affiliate' 
		WHEN t.AffiliateID IN (56662,56663)	THEN 'Direct'
		ELSE t.Channel END AS Channel
		,current_timestamp()

		from dwh_daily_process.migration_tables.Ext_Dim_Channel_Affiliate_UnifyCode t 


;
END;
