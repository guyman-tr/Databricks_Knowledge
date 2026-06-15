SELECT bdid.CID
		,bdid.DailyInterest
		,bdid.FundsForInterest
		,bdid.DailyInterestPercentage
		,bdid.DateID
		,bdid.DayOfInterest
		,bdid.CountryID
		,dco.Name CountryName
		,bdid.PlayerLevelID
		,bdid.RegulationID
		,bdim.MonthOfInterest
		,bdim.FinalTaxedlnterest
		,bdim.ValidFrom
		,bdic.ConsentStatusID
		,bdic.ValidFrom ValidFromConsent
		,bdic.ValidTo
FROM BI_DB_InterestDaily bdid
LEFT JOIN BI_DB_InterestMonthly bdim
ON bdid.CID = bdim.CID
AND EOMONTH(bdid.DayOfInterest) = EOMONTH(bdim.MonthOfInterest)
LEFT JOIN BI_DB_InterestConsent bdic
ON bdid.CID = bdic.CID
AND bdid.DayOfInterest>=bdic.ValidFrom
AND bdid.DayOfInterest<=bdic.ValidTo
JOIN DWH.dbo.Dim_Country dco
ON bdid.CountryID = dco.CountryID
WHERE bdid.DateID>=20200101
AND bdid.PlayerLevelID IN (2,6,7)
AND bdid.RegulationID IN (1,2,4,10)
and bdid.DailyInterest>0