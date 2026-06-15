SELECT [dc].[RealCID]
, dc1.[Region]
, dc1.MarketingRegionManualName AS MarketingRegion
, dc1.Name AS Country
, LOWER([dc].[City]) AS City
, (CASE WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 29 THEN '25-29'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 30 AND 34 THEN '30-34'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 39 THEN '35-39'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 40 AND 49 THEN '40-49'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 50 AND 59 THEN '50-59'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 60 AND 69 THEN '60-69'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) >= 70 THEN '70+'
	ELSE 'N/A' END) AS AgeGroup
, CAST(dc.FirstDepositDate AS DATE) AS FTD_Date
, EOMONTH(dc.FirstDepositDate) AS FTD_Month
, fd.[FirstNewFundedDate]
, EOMONTH(fd.[FirstNewFundedDate]) AS [FirstFundedMonth]
, dc.[AffiliateID]
, [da].[Contact]
, [dch].[Channel]
, [dch].[SubChannel]
, [ffa].[FirstAction]
, [ffa].[FirstAction_Detailed]
, [ltv].[ClusterDetail]
, [ltv].[Seniority]
, [ltv].[EquityTier]
, [fd].[Club]
,  bdlba.Revenue8Y_LTV_New AS LTV
, bdlba.Revenue8Y_LTV_NoExtreme_New AS LTVnoExtreme
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions] ltv WITH (NOLOCK)
JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba
ON ltv.RealCID = bdlba.CID
JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
	ON ltv.RealCID = dc.[RealCID]
JOIN [DWH_dbo].[Dim_Country] dc1 
	ON dc1.[CountryID] = dc.[CountryID]
LEFT JOIN [DWH_dbo].[Dim_Affiliate] da WITH (NOLOCK)
	ON dc.[AffiliateID] = da.[AffiliateID]
LEFT JOIN [DWH_dbo].[Dim_Channel] dch WITH (NOLOCK)
	ON dc.[SubChannelID] = dch.[SubChannelID]
LEFT JOIN [BI_DB_dbo].[BI_DB_First5Actions] ffa ON ffa.CID = ltv.[RealCID]
LEFT JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON fd.CID = ltv.RealCID
WHERE --[ltv].[FirstFundedMonth] IS NOT NULL AND [ltv].[FirstFundedMonth] >= '20210101' AND dc.BirthDate >= '18000101'
[dc].[IsValidCustomer] = 1 AND [dc].[VerificationLevelID] >= 2 AND [dc].[FirstDepositDate] >= '20230101'

UNION ALL

SELECT [dc].[RealCID]
, 'Global' AS [Region]
, 'Global' AS MarketingRegion
, dc1.Name AS Country
, LOWER([dc].[City]) AS City
, (CASE WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 29 THEN '25-29'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 30 AND 34 THEN '30-34'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 39 THEN '35-39'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 40 AND 49 THEN '40-49'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 50 AND 59 THEN '50-59'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) BETWEEN 60 AND 69 THEN '60-69'
	WHEN FLOOR(DATEDIFF(DAY, dc.BirthDate, GETDATE()) / 365.25) >= 70 THEN '70+'
	ELSE 'N/A' END) AS AgeGroup
, CAST(dc.FirstDepositDate AS DATE) AS FTD_Date
, EOMONTH(dc.FirstDepositDate) AS FTD_Month
, fd.[FirstNewFundedDate]
, EOMONTH(fd.[FirstNewFundedDate]) AS [FirstFundedMonth]
, dc.[AffiliateID]
, [da].[Contact]
, [dch].[Channel]
, [dch].[SubChannel]
, [ffa].[FirstAction]
, [ffa].[FirstAction_Detailed]
, [ltv].[ClusterDetail]
, [ltv].[Seniority]
, [ltv].[EquityTier]
, [fd].[Club]
,bdlba.Revenue8Y_LTV_New AS LTV
, bdlba.Revenue8Y_LTV_NoExtreme_New AS LTVnoExtreme
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions] ltv WITH (NOLOCK)
JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba
ON ltv.RealCID = bdlba.CID
JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
	ON ltv.RealCID = dc.[RealCID]
JOIN [DWH_dbo].[Dim_Country] dc1 
	ON dc1.[CountryID] = dc.[CountryID]
LEFT JOIN [DWH_dbo].[Dim_Affiliate] da WITH (NOLOCK)
	ON dc.[AffiliateID] = da.[AffiliateID]
LEFT JOIN [DWH_dbo].[Dim_Channel] dch WITH (NOLOCK)
	ON dc.[SubChannelID] = dch.[SubChannelID]
LEFT JOIN [BI_DB_dbo].[BI_DB_First5Actions] ffa ON ffa.CID = ltv.[RealCID]
LEFT JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON fd.CID = ltv.RealCID
WHERE --[ltv].[FirstFundedMonth] IS NOT NULL AND [ltv].[FirstFundedMonth] >= '20210101' AND dc.BirthDate >= '18000101'
[dc].[IsValidCustomer] = 1 AND [dc].[VerificationLevelID] >= 2 AND [dc].[FirstDepositDate] >= '20230101'