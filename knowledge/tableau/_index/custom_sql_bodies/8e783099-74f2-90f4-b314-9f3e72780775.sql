SELECT	bdcmpfd.Active_Month
		,bdcmpfd.ActiveDate
		,bdcmpfd.NewMarketingRegion
		,bdcmpfd.Region
		,bdcmpfd.Country
		,bdcmpfd.EOM_Regulation
		,bdcmpfd.EOM_Club
		,bdcmpfd.V2_Complete
		,bdcmpfd.V3_Complete
		,bdcmpfd.ClusterDetail
		,CASE WHEN bdcmpfd.Seniority = 0 THEN '0. New FTD'
			WHEN [Seniority] BETWEEN 1 AND 3 THEN '1. 1-3 Months'
			WHEN [Seniority] BETWEEN 4 AND 6 THEN '2. 4-6 Months'
			WHEN [Seniority] BETWEEN 7 AND 9 THEN '3. 7-9 Months'
			WHEN [Seniority] BETWEEN 10 AND 12 THEN '4. 10-12 Months'
			WHEN [Seniority] >= 13 AND [Seniority] <=24 THEN '5. 13-24 Months'
			WHEN [Seniority] >= 25 then '6. > 24 Months'
			ELSE NULL END [SenioritySegment]
		,COUNT(DISTINCT bdcmpfd.CID) [CountCID]
		,SUM(CASE WHEN DATEDIFF(MONTH, bdcmpfd.FTDdate, bdcmpfd.ActiveDate) = 0 AND bdcmpfd.FTDdate IS NOT NULL THEN 1 ELSE 0 END) [IsFTD_ThisM]
		,SUM(CASE WHEN DATEDIFF(MONTH, bdcmpfd.FTDdate, bdcmpfd.ActiveDate) = 0 AND bdcmpfd.FTDdate IS NOT NULL THEN bdcmpfd.FTDA ELSE 0 END) [FTDA_ThisM]
		,SUM(CASE WHEN DATEDIFF(WEEK, bdcmpfd.RegDate, bdcmpfd.ActiveDate) = 0 AND bdcmpfd.RegDate IS NOT NULL THEN 1 ELSE 0 END) [IsReg_ThisM]
		,SUM(CASE WHEN bdcmpfd.EOM_Club IN ('Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond') THEN 1 ELSE 0 END) [InClub]
		,SUM(CASE WHEN bdcmpfd.EOM_Club IN ('Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond') AND bdcmpfd.IsFunded_New = 1 THEN 1 ELSE 0 END) [InClubFunded]
		,SUM(bdcmpfd.EOM_IsFunded) [Funded>25]
		,SUM(bdcmpfd.IsEOM_Funded_NEW) [Funded>0]
		,SUM(bdcmpfd.V2_Complete) [Verified_L2_Users]
		,SUM(bdcmpfd.V3_Complete) [Verified_L3_Users]
		,SUM(bdcmpfd.Seniority) [Seniority_Total]
		,SUM(bdcmpfd.TotalDeposits) [TotalDeposits]
		,SUM(bdcmpfd.CountDeposits) [CountDeposits]
		,SUM(CASE WHEN bdcmpfd.TotalDeposits > 0 THEN 1 ELSE 0 END) [DidDeposit_ThisM]
		,SUM(bdcmpfd.NetDeposits) [NetDeposits_Total]
		,SUM(bdcmpfd.TotalCashouts) [TotalCashouts]
		,SUM(bdcmpfd.CashoutsAdjusted) [CashoutsAdjusted_Total]
		,SUM(bdcmpfd.WithdrawalToWallet) [WithdrawalToWallet]
		,SUM(CASE WHEN bdcmpfd.TotalCashouts > 0 THEN 1 ELSE 0 END) [DidCO_ThisM]
		,SUM(bdcmpfd.ActiveUser) [ActivelyLogin]
		,SUM(bdcmpfd.Active) [ActivelyHoldPosition]
		,SUM(bdcmpfd.ActiveOpen) [ActivelyOpenPosition]
		,SUM(bdcmpfd.Revenue_Total) [Revenue_Total]
		,SUM(bdcmpfd.Revenue_Real_Stocks) [Revenue_Real_Stocks]
		,SUM(bdcmpfd.Revenue_CFD_Stocks) [Revenue_CFD_Stocks]
		,SUM(bdcmpfd.Revenue_Real_Crypto) Revenue_Real_Crypto
		,SUM(bdcmpfd.Revenue_CFD_Crypto) Revenue_CFD_Crypto
		,SUM(bdcmpfd.[Revenue_FX/Comm/Ind]) [Revenue_FX/Comm/Ind]
		,SUM(bdcmpfd.Revenue_Copy) Revenue_Copy
		,SUM(CASE WHEN bdcmpfd.Revenue_Total > 0 THEN 1 ELSE 0 END) [RevenueGeneratingUsers]
		,SUM(CASE WHEN bdcmpfd.Revenue_Total < 0 THEN 1 ELSE 0 END) [RevenueLosingUsers]
		,SUM(CASE WHEN bdcmpfd.Revenue_Total < 0 THEN bdcmpfd.Revenue_Total ELSE 0 END) [RevenueLoss]
		,SUM(CASE WHEN bdcmpfd.Revenue_Total <> 0 AND bdcmpfd.Revenue_Total IS NOT NULL THEN 1 ELSE 0 END) [RevenueContributingUsers]
		,SUM(bdcmpfd.NewTrades_Total) NewTrades_Total
		,SUM(bdcmpfd.NewTrades_Real_Stocks) NewTrades_Real_Stocks
		,SUM(bdcmpfd.NewTrades_CFD_Stocks) NewTrades_CFD_Stocks
		,SUM(bdcmpfd.NewTrades_Real_Crypto) NewTrades_Real_Crypto
		,SUM(bdcmpfd.NewTrades_CFD_Crypto) NewTrades_CFD_Crypto
		,SUM(bdcmpfd.[NewTrades_FX/Comm/Ind]) [NewTrades_FX/Comm/Ind]
		,SUM(bdcmpfd.NewTrades_Copy) NewTrades_Copy
		,SUM(bdcmpfd.NewTrades_Real_Stocks_Lev1) NewTrades_Real_Stocks_Lev1
		,SUM(bdcmpfd.NewTrades_CFD_Stocks_LevCFD) NewTrades_CFD_Stocks_LevCFD
		,SUM(bdcmpfd.NewTrades_Real_Crypto_Lev1) NewTrades_Real_Crypto_Lev1
		,SUM(bdcmpfd.NewTrades_CFD_Crypto_LevCFD) NewTrades_CFD_Crypto_LevCFD
		,SUM(bdcmpfd.AmountIn_NewTrades_Total) AmountIn_NewTrades_Total
		,SUM(bdcmpfd.AmountIn_NewTrades_Real_Stocks) AmountIn_NewTrades_Real_Stocks
		,SUM(bdcmpfd.AmountIn_NewTrades_CFD_Stocks) AmountIn_NewTrades_CFD_Stocks 
		,SUM(bdcmpfd.AmountIn_NewTrades_Real_Crypto) AmountIn_NewTrades_Real_Crypto
		,SUM(bdcmpfd.AmountIn_NewTrades_CFD_Crypto) AmountIn_NewTrades_CFD_Crypto
		,SUM(bdcmpfd.[AmountIn_NewTrades_FX/Comm/Ind]) [AmountIn_NewTrades_FX/Comm/Ind]
		,SUM(bdcmpfd.AmountIn_NewTrades_Copy) AmountIn_NewTrades_Copy
		,SUM(bdcmpfd.AmountIn_NewTrades_Real_Stocks_Lev1) AmountIn_NewTrades_Real_Stocks_Lev1
		,SUM(bdcmpfd.AmountIn_NewTrades_CFD_Stocks_LevCFD) AmountIn_NewTrades_CFD_Stocks_LevCFD
		,SUM(bdcmpfd.AmountIn_NewTrades_Real_Crypto_Lev1) AmountIn_NewTrades_Real_Crypto_Lev1
		,SUM(bdcmpfd.AmountIn_NewTrades_CFD_Crypto_LevCFD) AmountIn_NewTrades_CFD_Crypto_LevCFD
		,SUM(bdcmpfd.EOM_Equity) EOM_Equity
		,SUM(bdcmpfd.EOM_Equity_Copy) EOM_Equity_Copy
		,SUM(bdcmpfd.EOM_Equity_Real_Crypto) EOM_Equity_Real_Crypto
		,SUM(bdcmpfd.EOM_Equity_Real_Stocks) EOM_Equity_Real_Stocks
		,SUM(bdcmpfd.EOM_Equity_CFD_Crypto) EOM_Equity_CFD_Crypto
		,SUM(bdcmpfd.EOM_Equity_CFD_Stocks) EOM_Equity_CFD_Stocks
		,SUM(bdcmpfd.[EOM_Equity_FX/Comm/Ind]) [EOM_Equity_FX/Comm/Ind]
		,SUM(bdcmpfd.EOM_Equity_Real_Crypto_Lev1) EOM_Equity_Real_Crypto_Lev1
		,SUM(bdcmpfd.EOM_Equity_Real_Stocks_LevCFD) EOM_Equity_Real_Stocks_LevCFD
		,SUM(bdcmpfd.EOM_Equity_CFD_Crypto_Lev1) EOM_Equity_CFD_Crypto_Lev1
		,SUM(bdcmpfd.EOM_Equity_CFD_Stocks_LevCFD) EOM_Equity_CFD_Stocks_LevCFD
		,SUM(CASE WHEN bdcmpfd.EOM_Equity < 0 THEN 1 ELSE 0 END) [NegativeEquityUsers]
		,SUM(bdcmpfd.PnL_Total) PnL_Total
		,SUM(bdcmpfd.PnL_Copy) PnL_Copy
		,SUM(bdcmpfd.PnL_Real_Stocks) PnL_Real_Stocks
		,SUM(bdcmpfd.PnL_CFD_Stocks) PnL_CFD_Stocks
		,SUM(bdcmpfd.PnL_Real_Crypto) PnL_Real_Crypto
		,SUM(bdcmpfd.PnL_CFD_Crypto) PnL_CFD_Crypto
		,SUM(bdcmpfd.[PnL_FX/Comm/Ind]) [PnL_FX/Comm/Ind]
		,SUM(CASE WHEN bdcmpfd.PnL_Total > 0 THEN 1 ELSE 0 END) [PnL_PositiveUsers]
		,SUM(CASE WHEN bdcmpfd.PnL_Total < 0 AND bdcmpfd.PnL_Total IS NOT NULL THEN 1 ELSE 0 END) [PnL_NegativeUsers]
		,SUM(bdcmpfd.IsChurn_ThisM) [IsChurn_ThisM]
		,SUM(bdcmpfd.IsWB_ThisM) [IsWB_ThisM]
FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdcmpfd
WHERE bdcmpfd.Active_Month >= 202201
GROUP BY bdcmpfd.Active_Month
		,bdcmpfd.ActiveDate
		,bdcmpfd.NewMarketingRegion
		,bdcmpfd.Region
		,bdcmpfd.Country
		,bdcmpfd.EOM_Regulation
		,bdcmpfd.EOM_Club
		,bdcmpfd.V2_Complete
		,bdcmpfd.V3_Complete
		,bdcmpfd.ClusterDetail
		,CASE WHEN bdcmpfd.Seniority = 0 THEN '0. New FTD'
			WHEN [Seniority] BETWEEN 1 AND 3 THEN '1. 1-3 Months'
			WHEN [Seniority] BETWEEN 4 AND 6 THEN '2. 4-6 Months'
			WHEN [Seniority] BETWEEN 7 AND 9 THEN '3. 7-9 Months'
			WHEN [Seniority] BETWEEN 10 AND 12 THEN '4. 10-12 Months'
			WHEN [Seniority] >= 13 AND [Seniority] <=24 THEN '5. 13-24 Months'
			WHEN [Seniority] >= 25 then '6. > 24 Months'
			ELSE NULL END