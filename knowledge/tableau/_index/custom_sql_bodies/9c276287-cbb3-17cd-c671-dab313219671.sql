SELECT bdid.CID,
		co.Name,
		bdid.RegulationID,
		dr.Name RegName,
        bdid.FundsForInterest as 'Balance earning interest',
		co.Region,
		bdid.DateID,
		bdid.DailyInterest as 'Daily interest earned',
		dpl.Name Club_Tier,
		bdid.DayOfInterest,
		bdim.CID MonthlyCID,
		bdim.MonthOfInterest,
		bdim.MonthlyAccumulatedInterest,
		bdim.FinalTaxedlnterest,
		Consent.ConsentStatusID
FROM BI_DB_dbo.BI_DB_InterestDaily bdid
JOIN [DWH_dbo].[Dim_Country] co
ON bdid.CountryID = co.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON bdid.PlayerLevelID=dpl.PlayerLevelID
JOIN [DWH_dbo].[Dim_Regulation] dr
ON bdid.RegulationID=dr.ID
LEFT JOIN BI_DB_dbo.BI_DB_InterestMonthly bdim
ON bdid.CID = bdim.CID
AND EOMONTH (bdid.DayOfInterest)=EOMONTH (bdim.MonthOfInterest)
LEFT JOIN (SELECT  bdic.CID
			,bdic.ConsentStatusID
			,bdic.ValidFrom
			,bdic.ValidTo
			FROM BI_DB_dbo.BI_DB_InterestConsent bdic) Consent
ON bdid.CID=Consent.CID
AND bdid.DayOfInterest>=Consent.ValidFrom
AND bdid.DayOfInterest<=Consent.ValidTo

WHERE bdid.DateID >=20200101
AND (bdid.PlayerLevelID in (2, 3, 6, 7) 
     OR (co.CountryID IN (57, 72, 143, 154, 196) 
         AND bdid.PlayerLevelID = 5))
AND bdid.CountryID NOT IN (219)
AND bdid.RegulationID in (1,2,4,9,10,11)
AND bdid.DailyInterest>0