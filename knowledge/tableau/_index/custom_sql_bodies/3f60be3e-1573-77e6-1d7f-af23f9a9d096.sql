SELECT c.FullDate
		, COUNT(DISTINCT CID) CIDs
FROM BI_DB_dbo.BI_DB_InterestConsent
JOIN (SELECT dd.FullDate
		FROM DWH_dbo.Dim_Date dd
		 WHERE dd.IsLastDayOfMonth='Y')c
ON CAST(ValidFrom AS DATE)<=c.FullDate
AND CAST(ValidTo AS DATE)>=c.FullDate
	JOIN DWH_dbo.Dim_Customer dc
	ON CID=dc.RealCID
	JOIN [DWH_dbo].[Dim_Country] co
ON dc.CountryID = co.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID=dpl.PlayerLevelID
JOIN [DWH_dbo].[Dim_Regulation] dr
ON dc.RegulationID=dr.ID
WHERE ConsentStatusID=1
AND (dc.PlayerLevelID in (2, 3, 6, 7) 
     OR (co.CountryID IN (57, 72, 143, 154, 196) 
         AND dc.PlayerLevelID = 5))
AND dc.CountryID NOT IN (219)
AND dc.RegulationID in (1,2,4,9,10,11)
GROUP BY c.FullDate