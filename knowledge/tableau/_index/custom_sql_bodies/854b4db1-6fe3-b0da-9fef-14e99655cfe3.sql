SELECT da.AffiliateID,
	da.DateCreated,
	   da.Contact,
	   da.ContractName,
	   da.AccountActivated,
       bdmmrd.CountryID,
	   bdmmrd.YearMonth,
	   bdmmrd.YearMonthID,
	   bdmmrd.CountryName, 
	   bdmmrd.NewMarketingRegion as Region,
	   bdmmrd.Desk,
	   bdmmrd.Channel,
	   bdmmrd.SubChannel,
	   bdmmrd.[Organic/Paid],
	   bdmmrd.ContractType,
	   CASE WHEN da.AffiliatesGroupsName LIKE ('%Rory%') OR da.AffiliatesGroupsName='UK Affiliates' THEN 'Rory Hatherell'
					 WHEN da.AffiliatesGroupsName LIKE ('%Arie%') THEN 'Arie Cohen'
					 WHEN da.AffiliatesGroupsName LIKE ('%Luciano%') THEN 'Luciano lorens'
					 WHEN da.AffiliatesGroupsName LIKE ('%Monika%') THEN 'Monika Hakak'
					 WHEN da.AffiliatesGroupsName LIKE ('%Majd%') THEN 'Majd Dagash'
					 WHEN da.AffiliatesGroupsName LIKE ('%Mathieu%') THEN 'Mathieu Sommerfeld'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nimrod%') THEN 'Nimrod Burla'
					 WHEN da.AffiliatesGroupsName LIKE ('%Nurith%') THEN 'Nurith Terracina'
					 WHEN da.AffiliatesGroupsName LIKE ('%Ran%') THEN 'Ran Regev'
					 WHEN da.AffiliatesGroupsName LIKE ('%Shiran%') THEN 'Shiran Herzberg'
					 WHEN da.AffiliatesGroupsName LIKE ('%Troy%') THEN 'Troy Mulder'
					 WHEN da.AffiliatesGroupsName LIKE ('%David%') THEN 'David Dahan'
					 WHEN da.AffiliatesGroupsName LIKE ('%Lee Aichel%') THEN 'Lee Aichel'
					 WHEN da.AffiliatesGroupsName LIKE ('%Lucia%') THEN  'Lucia'
					 END AS Affiliate_managers,
	   da.AffiliatesGroupsName,
	   SUM(bdmmrd.TotalCost) TotalCost,
	   SUM(bdmmrd.RevShare_Comm) RevShare_Comm,
	   SUM(bdmmrd.CPA_Comm) CPA_Comm,
	   SUM(bdmmrd.CPL_Comm) CPL_Comm,
	   SUM(bdmmrd.RAF_Comm) RAF_Comm,
	   SUM(bdmmrd.eCost) eCost,
	   SUM(bdmmrd.Registration) Registration,
	   SUM(bdmmrd.FTD) FTD,
	   SUM(bdmmrd.EFTD) EFTD,
	   SUM(bdmmrd.FTDA) FTDA,
	   SUM(bdmmrd.NetRevenues) NetRevenues,
	   SUM(bdmmrd.VerificationLevelID2) VerificationLevelID2,
	   SUM(bdmmrd.VerificationLevelID3) VerificationLevelID3,
	   SUM(bdmmrd.Installs) Installs,
	   SUM(bdmmrd.TotalDeposit) TotalDeposit,
	   SUM(bdmmrd.LTV_NoExtreme) LTV_NoExtreme,
	   SUM(bdmmrd.GLTV) GLTV,
	   SUM(bdmmrd.FTDfromLTV) FTDfromLTV,
	   SUM(bdmmrd.PastGRevenue) PastGRevenue,
	   SUM(bdmmrd.SameDayFTD) SameDayFTD,
	   SUM(bdmmrd.IsRev) IsRev,
	   SUM(bdmmrd.Rev10) Rev10
FROM BI_DB_dbo.BI_DB_MarketingMonthlyRawData bdmmrd
JOIN DWH_dbo.Dim_Affiliate da
	ON bdmmrd.AffiliateID = da.AffiliateID
LEFT JOIN (
		SELECT  bdmmrd.AffiliateID
		FROM BI_DB_dbo.BI_DB_MarketingMonthlyRawData bdmmrd
		WHERE bdmmrd.YearMonthID<YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month(CAST( DATEADD(MONTH,-3, GETDATE()) as DATE))
		GROUP BY bdmmrd.AffiliateID
		HAVING SUM(ISNULL(bdmmrd.FTD,0))=0
	  ) a
	ON bdmmrd.AffiliateID=a.AffiliateID
WHERE bdmmrd.YearMonthID>=YEAR( CAST( DATEADD(MONTH,- 1, GETDATE() )  as date))*100+month(CAST( DATEADD(MONTH,-3, GETDATE()) as DATE))
	AND (da.AffiliatesGroupsName LIKE ('%Rory%') OR  da.AffiliatesGroupsName LIKE ('%Arie%') or da.AffiliatesGroupsName LIKE ('%Luciano%')  
				OR da.AffiliatesGroupsName LIKE ('%Monika%') or da.AffiliatesGroupsName LIKE ('%Majd%') OR da.AffiliatesGroupsName LIKE ('%Mathieu%') 
				OR da.AffiliatesGroupsName LIKE ('%Nimrod%') or da.AffiliatesGroupsName LIKE ('%Nurith%') or da.AffiliatesGroupsName LIKE ('%Ran%') 
				or da.AffiliatesGroupsName LIKE ('%Shiran%') or da.AffiliatesGroupsName LIKE ('%Troy%') or da.AffiliatesGroupsName LIKE ('%David%')
				or da.AffiliatesGroupsName LIKE ('%Lee Aichel%') or da.AffiliatesGroupsName LIKE ('%Lucia%')
				OR da.AffiliatesGroupsName='UK Affiliates')
			AND da.AffiliatesGroupsName NOT IN ('Ariela','Ranit')
			AND da.Channel IN ('Affiliate')
			AND da.ContractName NOT LIKE ('%Terminated%')
			AND (da.DateCreated>=CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -3,GETDATE())), 0) AS DATE) OR a.AffiliateID IS NOT NULL)
GROUP BY   da.AffiliateID,
	da.DateCreated,
		   da.Contact,
		   da.ContractName,
		   da.AccountActivated,
		   bdmmrd.CountryID,
		   bdmmrd.YearMonth,
		   bdmmrd.YearMonthID,
		   bdmmrd.CountryName, 
		   bdmmrd.NewMarketingRegion,
		   bdmmrd.Desk,
		   bdmmrd.Channel,
		   bdmmrd.SubChannel,
		   bdmmrd.[Organic/Paid],
		   bdmmrd.ContractType,
		   CASE WHEN da.AffiliatesGroupsName LIKE ('%Rory%') OR da.AffiliatesGroupsName='UK Affiliates' THEN 'Rory Hatherell'
						 WHEN da.AffiliatesGroupsName LIKE ('%Arie%') THEN 'Arie Cohen'
						 WHEN da.AffiliatesGroupsName LIKE ('%Luciano%') THEN 'Luciano lorens'
						 WHEN da.AffiliatesGroupsName LIKE ('%Monika%') THEN 'Monika Hakak'
						 WHEN da.AffiliatesGroupsName LIKE ('%Majd%') THEN 'Majd Dagash'
						 WHEN da.AffiliatesGroupsName LIKE ('%Mathieu%') THEN 'Mathieu Sommerfeld'
						 WHEN da.AffiliatesGroupsName LIKE ('%Nimrod%') THEN 'Nimrod Burla'
						 WHEN da.AffiliatesGroupsName LIKE ('%Nurith%') THEN 'Nurith Terracina'
						 WHEN da.AffiliatesGroupsName LIKE ('%Ran%') THEN 'Ran Regev'
						 WHEN da.AffiliatesGroupsName LIKE ('%Shiran%') THEN 'Shiran Herzberg'
						 WHEN da.AffiliatesGroupsName LIKE ('%Troy%') THEN 'Troy Mulder'
						 WHEN da.AffiliatesGroupsName LIKE ('%David%') THEN 'David Dahan'
						 WHEN da.AffiliatesGroupsName LIKE ('%Lee Aichel%') THEN 'Lee Aichel'
					     WHEN da.AffiliatesGroupsName LIKE ('%Lucia%') THEN  'Lucia'
						 END ,
		   da.AffiliatesGroupsName
HAVING SUM(ISNULL(bdmmrd.FTD,0))>0