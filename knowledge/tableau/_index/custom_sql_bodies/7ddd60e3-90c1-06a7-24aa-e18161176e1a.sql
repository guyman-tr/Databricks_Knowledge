SELECT DISTINCT bdcwpfd.YearWeekNumber
		,bdcwpfd.CalendarYear
		,bdcwpfd.SSWeekNumberOfYear
		,CAST(bdcwpfd.FirstDayOfWeek AS DATE) [FirstDayOfWeek]
		,bdcwpfd.NewMarketingRegion [MarketingRegion]
		,bdcwpfd.Region
		,bdcwpfd.Country
		,bdcwpfd.EOW_Regulation
		,bdcwpfd.EOW_Club
		,bdcwpfd.Weekly_Classification
		,CASE WHEN bdcwpfd.Seniority = 0 THEN '0. New FTD'
			WHEN [Seniority] BETWEEN 1 AND 3 THEN '1. 1-3 Months'
			WHEN [Seniority] BETWEEN 4 AND 6 THEN '2. 4-6 Months'
			WHEN [Seniority] BETWEEN 7 AND 9 THEN '3. 7-9 Months'
			WHEN [Seniority] BETWEEN 10 AND 12 THEN '4. 10-12 Months'
			WHEN [Seniority] >= 13 AND [Seniority] <=24 THEN '5. 13-24 Months'
			WHEN [Seniority] >= 25 then '6. > 24 Months'
			ELSE NULL END [SenioritySegment]
		,bdcwpfd.V2_Complete
		,bdcwpfd.V3_Complete
		,COUNT(DISTINCT bdcwpfd.CID) [CID_Count]
		,SUM(CASE WHEN DATEDIFF(WEEK, bdcwpfd.FTDdate,bdcwpfd.FirstDayOfWeek) = 0 AND bdcwpfd.FTDdate IS NOT NULL THEN 1 ELSE 0 END) [IsFTD_ThisW]
		,SUM(CASE WHEN DATEDIFF(WEEK, bdcwpfd.FTDdate,bdcwpfd.FirstDayOfWeek) = 0 AND bdcwpfd.FTDdate IS NOT NULL THEN bdcwpfd.FTDA ELSE 0 END) [FTDA_ThisW]
		,SUM(CASE WHEN DATEDIFF(WEEK, bdcwpfd.RegDate,bdcwpfd.FirstDayOfWeek) = 0 AND bdcwpfd.RegDate IS NOT NULL THEN 1 ELSE 0 END) [IsReg_ThisW]
		,SUM(CASE WHEN bdcwpfd.EOW_Club IN ('Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond') THEN 1 ELSE 0 END) [InClub]
		,SUM(CASE WHEN bdcwpfd.EOW_Club IN ('Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond') AND bdcwpfd.IsFunded_New = 1 THEN 1 ELSE 0 END) [InClubFunded]
		,SUM(bdcwpfd.Seniority) [SeniorityTotal]
		,SUM(CASE WHEN bdcwpfd.Revenue_Total > 0 THEN 1 ELSE 0 END) [RevenueGeneratingUsers]
		,SUM(CASE WHEN bdcwpfd.Revenue_Total < 0 THEN 1 ELSE 0 END) [RevenueLosingUsers]
		,SUM(CASE WHEN bdcwpfd.Revenue_Total <> 0 AND bdcwpfd.Revenue_Total IS NOT NULL THEN 1 ELSE 0 END) [RevenueContributingUsers]
		,SUM(bdcwpfd.ActiveUser) [ActivelyLogin]
		,SUM(bdcwpfd.Active) [ActivelyHoldPosition]
		,SUM(bdcwpfd.ActiveOpen) [ActivelyOpenPosition]
		,SUM(bdcwpfd.EOW_IsFunded) [Funded>25]
		,SUM(bdcwpfd.IsFunded_New) [Funded>0]
		,SUM(bdcwpfd.Revenue_Total) [Revenue_Total]
		,SUM(bdcwpfd.Revenue_Copy) [Revenue_Copy]
		,SUM(bdcwpfd.Revenue_Real_Stocks) [Revenue_Real_Stocks]
		,SUM(bdcwpfd.Revenue_CFD_Stocks) [Revenue_CFD_Stocks]
		,SUM(bdcwpfd.Revenue_Real_Crypto) [Revenue_Real_Crypto]
		,SUM(bdcwpfd.Revenue_CFD_Crypto) [Revenue_CFD_Crypto]
		,SUM(bdcwpfd.[Revenue_FX/Comm/Ind]) [Revenue_FX/Comm/Ind]
		,SUM(bdcwpfd.AUM) [AUM]
		,SUM(bdcwpfd.Equity) [Equity]
		,SUM(bdcwpfd.RealizedEquity) [RealizedEquity]
		,SUM(CASE WHEN bdcwpfd.Equity < 0 AND bdcwpfd.Equity IS NOT NULL THEN 1 ELSE 0 END) [NegativeEquityUsers]
		,SUM(bdcwpfd.EOW_Equity_Copy) [EOW_Equity_Copy]
		,SUM(bdcwpfd.EOW_Equity_Real_Crypto) [EOW_Equity_Real_Crypto]
		,SUM(bdcwpfd.EOW_Equity_Real_Stocks) [EOW_Equity_Real_Stocks]
		,SUM(bdcwpfd.EOW_Equity_CFD_Crypto) [EOW_Equity_CFD_Crypto]
		,SUM(bdcwpfd.EOW_Equity_CFD_Stocks) [EOW_Equity_CFD_Stocks]
		,SUM(bdcwpfd.[EOW_Equity_FX/Comm/Ind]) [EOW_Equity_FX/Comm/Ind]
		,SUM(bdcwpfd.EOW_Equity_Real_Stocks_LevCFD) [EOW_Equity_Real_Stocks_LevCFD]
		,SUM(bdcwpfd.EOW_Equity_CFD_Stocks_LevCFD) [EOW_Equity_CFD_Stocks_LevCFD]
		,SUM(bdcwpfd.EOW_Equity_CFD_Crypto_Lev1) [EOW_Equity_CFD_Crypto_Lev1]
		,SUM(bdcwpfd.EOW_Equity_Real_Crypto_Lev1) [EOW_Equity_Real_Crypto_Lev1]
		,SUM(bdcwpfd.PnL_Total) [PnL_Total]
		,SUM(CASE WHEN bdcwpfd.PnL_Total > 0 THEN 1 ELSE 0 END) [PnL_PositiveUsers]
		,SUM(CASE WHEN bdcwpfd.PnL_Total < 0 AND bdcwpfd.PnL_Total IS NOT NULL THEN 1 ELSE 0 END) [PnL_NegativeUsers]
		,SUM(bdcwpfd.NewTrades_Total) [NewTradesCount_Total]
		,SUM(bdcwpfd.AmountIn_NewTrades_Total) [NewTradesAmount_Total]
		,SUM(bdcwpfd.TotalDeposits) [TotalDeposits]
		,SUM(bdcwpfd.CountDeposits) [CountDeposits]
		,SUM(bdcwpfd.TotalCashouts) [TotalCashouts]
		,SUM(bdcwpfd.WithdrawalToWallet) [WithdrawalToWallet]
		,SUM(CASE WHEN bdcwpfd.TotalDeposits > 0 THEN 1 ELSE 0 END) [DidDeposit_ThisW]
                ,SUM(CASE WHEN bdcwpfd.TotalCashouts > 0 THEN 1 ELSE 0 END) [DidCO_ThisW]
		,SUM(bdcwpfd.V2_Complete) [Verified_L2_Users]
		,SUM(bdcwpfd.V3_Complete) [Verified_L3_Users]
FROM BI_DB..BI_DB_CID_WeeklyPanel_FullData bdcwpfd
WHERE bdcwpfd.CalendarYear >= 2022
GROUP BY bdcwpfd.YearWeekNumber
		,bdcwpfd.CalendarYear
		,bdcwpfd.SSWeekNumberOfYear
		,CAST(bdcwpfd.FirstDayOfWeek AS DATE)
		,bdcwpfd.NewMarketingRegion
		,bdcwpfd.Region
		,bdcwpfd.Country
		,bdcwpfd.EOW_Regulation
		,bdcwpfd.EOW_Club
		,bdcwpfd.Weekly_Classification
		,CASE WHEN bdcwpfd.Seniority = 0 THEN '0. New FTD'
			WHEN [Seniority] BETWEEN 1 AND 3 THEN '1. 1-3 Months'
			WHEN [Seniority] BETWEEN 4 AND 6 THEN '2. 4-6 Months'
			WHEN [Seniority] BETWEEN 7 AND 9 THEN '3. 7-9 Months'
			WHEN [Seniority] BETWEEN 10 AND 12 THEN '4. 10-12 Months'
			WHEN [Seniority] >= 13 AND [Seniority] <=24 THEN '5. 13-24 Months'
			WHEN [Seniority] >= 25 then '6. > 24 Months'
			ELSE NULL END
		,bdcwpfd.V2_Complete
		,bdcwpfd.V3_Complete