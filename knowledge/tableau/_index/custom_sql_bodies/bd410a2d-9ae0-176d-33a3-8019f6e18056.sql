SELECT	bdcmpfd.Active_Month
		,EOMONTH(bdcmpfd.ActiveDate) [EndOfMonthDate]
		,bdcmpfd.CID
		,bdcmpfd.NewMarketingRegion
		,bdcmpfd.Country
		,dps.Name [PlayerStatus]
		,dc.RegisteredReal [RegistrationDate]
		,bdcmpfd.FTDdate
		,bdcmpfd.Seniority
		,bdcmpfd.Revenue_Total
		,bdcmpfd.EOM_Equity [RealizedEquity_EOM]
		,bdcmpfd.TotalDeposits [TotalDeposits_EOM]
		,bdcmpfd.TotalCashouts [TotalGrossCashout_EOM]
		,bdcmpfd.NetDeposits
		,bdcmpfd.CashoutsAdjusted [TotalAdjustedCashout]
		,bdcmpfd.PnL_Total
		,bdcmpfd.IsFunded_New [FundedMoreThan0]
		,bdcmpfd.EOM_IsFunded [FundedMoreThan25]
		,bdcmpfd.IsContacted
		,bdcmpfd.AccountManager
		,dc.Gender
		,bdcmpfd.EOM_Club [Club_EOM]
		,bdcmpfd.EOM_Regulation [Regulation_EOM]
		,bdcmpfd.ClusterDetail [ClusterClassification]
		,bdcmpfd.ActiveUser [ActiveLogin]
		,bdcmpfd.Active [ActiveHoldPositions]
		,bdcmpfd.ActiveOpen [ActiveOpenedPositions]
		,bdcmpfd.NewTrades_Total [NewTradesOpened]
FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdcmpfd
LEFT JOIN DWH..Dim_Customer dc ON bdcmpfd.CID = dc.RealCID
LEFT JOIN DWH..Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
WHERE bdcmpfd.Active_Month >= 202201
AND bdcmpfd.Active_Month <> (DATEPART(YEAR, GETDATE())*100+DATEPART(MONTH,GETDATE()))