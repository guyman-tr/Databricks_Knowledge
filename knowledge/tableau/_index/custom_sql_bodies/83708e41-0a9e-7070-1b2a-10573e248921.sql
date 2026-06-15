SELECT	bdid.CID,
		bdid.FundsForInterest,
		bdid.DailyInterestPercentage,
		bdid.Interest,
		bdid.SumOfPendingCashoutRequests,
		bdid.Bonus,
		bdid.YearlyInterestPercentage,
		bdid.DailyInterest as 'Daily interest earned',
		bdid.Credit-bdid.Interest AS 'Balance interest earned',
		bdid.RegulationID,
		dr.Name RegName,
		co.Name,
		co.Region,
                co.EU,
		dd.DateKey DateID,
		dd.FullDate DayOfInterest,
		bdcdpfd.EOD_Club Club_Tier,
		bdcdpfd.CID BalanceCID,
		bdcdpfd.Active_Month BalanceActive_Month,
		bdcdpfd.EOD_Club BalanceClub,
		bdcdpfd.RealizedEquity,
		bdim.CID MonthlyCID,
		bdim.MonthOfInterest,
		bdim.MonthlyAccumulatedInterest,
		bdim.FinalTaxedlnterest,
		Consent.ConsentStatusID ConsentStatusID,
		dd.IsLastDayOfMonth,
        tin.TIN_Value
FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpfd
JOIN DWH_dbo.Dim_Date dd 
	ON bdcdpfd.DateID=dd.DateKey
JOIN BI_DB_dbo.BI_DB_InterestDaily bdid
	ON bdcdpfd.CID = bdid.CID AND dd.DateKey = bdid.DateID
LEFT JOIN BI_DB_dbo.BI_DB_Tax_Compliance_TIN tin
	ON bdid.CID = tin.CID
JOIN [DWH_dbo].[Dim_Country] co
	ON bdcdpfd.Country= co.Name
JOIN [DWH_dbo].[Dim_Regulation] dr
	ON bdcdpfd.EOD_Regulation=dr.Name
LEFT JOIN BI_DB_dbo.BI_DB_InterestMonthly bdim
	ON bdid.CID = bdim.CID
	AND EOMONTH (bdid.DayOfInterest)=EOMONTH (bdim.MonthOfInterest)
LEFT JOIN  #InterestConsent Consent
ON bdcdpfd.CID=Consent.CID 
AND bdid.DayOfInterest>=Consent.ValidFrom
AND bdid.DayOfInterest<=Consent.ValidTo
--and Consent.ConsentStatusID=1
WHERE dd.DateKey >=20250101