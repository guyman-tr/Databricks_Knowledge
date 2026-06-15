SELECT consent.CID
	  ,consent.ConsentStatusID
	  ,consent.ValidFrom
	  ,consent.ValidTo
	  ,co.Name
		,dr.Name RegName
		,co.Region
		,dpl.Name Club_Tier
	  FROM (
			SELECT bdic.CID
				, bdic.ConsentStatusID
				,bdic.ValidFrom
				,bdic.ValidTo
				, ROW_NUMBER()OVER (PARTITION BY bdic.CID, YEAR(bdic.ValidFrom), MONTH(bdic.ValidFrom) ORDER BY bdic.ValidFrom DESC) AS rn
				FROM [BI_DB_dbo].[External_Interest_Trade_InterestConsent] bdic
				) consent
	JOIN DWH_dbo.Dim_Customer dc
	ON consent.CID=dc.RealCID
	JOIN [DWH_dbo].[Dim_Country] co
ON dc.CountryID = co.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID=dpl.PlayerLevelID
JOIN [DWH_dbo].[Dim_Regulation] dr
ON dc.RegulationID=dr.ID

WHERE consent.rn=1
AND (dc.PlayerLevelID in (1,2, 3, 6, 7) 
     OR (co.CountryID IN (57, 72, 143, 154, 196) 
         AND dc.PlayerLevelID = 5))
AND dc.CountryID NOT IN (219)
AND dc.RegulationID in (1,2,4,9,10,11)