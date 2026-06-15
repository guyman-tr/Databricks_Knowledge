SELECT sur.[SurveyID]
		  ,sur.[SurveyName]
		  ,CAST(sur.[CreatedDate] AS Date) CreatedDate
		  ,sur.[SystemModstamp]
		  ,sur.[cSAT]
		  ,sur.[CustomerEngagementID]
		  ,sur.AccountOwner
		  ,sur.[Q_ProfessionalService]
		  ,sur.[Q_HelpFulEconomic]
		  ,sur.[Q_Investmentchoices]
		  ,sur.[Q_Newproducts]
		  ,sur.[Q_WhichProducts1]
		  ,sur.[Q_WhichProducts2]
		  ,sur.[UpdateDate]
		  ,CASE WHEN dc1.Name IN ('Denmark','Finland','Netherlands','Norway','Sweden')  THEN 'Nordic'
            WHEN dc1.Name IN ('Poland','Romania','Slovakia','Slovenia','Czech Republic') THEN 'EE'
            WHEN dc1.Region IN ('South & Central America','Spain') THEN 'Spanish'
            WHEN dc1.Region IN ('Other Asia','China') THEN 'SEA'
            WHEN dc1.Region IN ('Arabic Other','Arabic GCC') THEN 'Arabic'
            WHEN dc1.Region IN ('French','German','Italian','UK','USA','Australia','Canada') THEN dc1.Region
            ELSE 'ROW' END ClubRegion
FROM BI_DB_SF_M_Users bdsmu
LEFT JOIN (SELECT  sur.[SurveyID]
		  ,sur.[OwnerID]
		  ,sur.[SurveyName]
		  ,sur.[CreatedDate]
		  ,sur.[CreatedyID]
		  ,sur.[SystemModstamp]
		  ,sur.[cSAT]
		  ,sur.[CustomerEngagementID]
		  ,ce.AccountOwner
		  ,ce.CID
		  ,sur.[Q_ProfessionalService]
		  ,sur.[Q_HelpFulEconomic]
		  ,sur.[Q_Investmentchoices]
		  ,sur.[Q_Newproducts]
		  ,sur.[Q_WhichProducts1]
		  ,sur.[Q_WhichProducts2]
		  ,sur.[UpdateDate]

		  FROM [BI_DB].[dbo].[BI_DB_SF_AM_Survey] sur
		  INNER JOIN [BI_DB].[dbo].[BI_DB_SF_CustomerEngagement] ce
		  ON sur.CustomerEngagementID = ce.EngagementID
                    where sur.cSAT IS NOT NULL) sur
		  JOIN DWH.dbo.Dim_Customer dc
		  ON sur.CID = dc.RealCID
		  JOIN DWH.dbo.Dim_Country dc1
		  ON dc.CountryID = dc1.CountryID
ON bdsmu.Name = sur.AccountOwner
AND sur.CreatedDate>=DATEADD(mm,-5,SYSUTCDATETIME())
LEFT JOIN DWH.dbo.Dim_Manager dm
ON CAST(bdsmu.AccountManagerID AS INT) = dm.ManagerID
WHERE bdsmu.ToDate = '9999-12-31'