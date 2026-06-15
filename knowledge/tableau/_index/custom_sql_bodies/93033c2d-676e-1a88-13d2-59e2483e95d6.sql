SELECT bdcdpfd.CID
	  ,bdcdpfd.DateID
	  ,bdcdpfd.ActiveDate
	  ,bdcdpfd.Country
	  ,bdcdpfd.V2_Complete
	  ,bdcdpfd.V3_Complete
	  ,bdcdpfd.EOD_Club
	  ,bdcdpfd.EOD_Regulation
	  ,bdcdpfd.Equity
	  ,bdcdpfd.RealizedEquity
	  ,bdcdpfd.AUM
	  ,bdcdpfd.Credit
	  ,bdcdpfd.Active
	  ,bdcdpfd.ActiveOpen
	  ,bdcdpfd.IsOpen_Copy
	  ,bdcdpfd.Active_Real_Stocks
	  ,bdcdpfd.Active_CFD_Stocks
	  ,bdcdpfd.Active_Real_Crypto
	  ,bdcdpfd.Active_CFD_Crypto
	  ,bdcdpfd.[Active_FX/Comm/Ind]
	  ,bdcdpfd.ActiveOpen_Real_Stocks
	  ,bdcdpfd.ActiveOpen_CFD_Stocks
	  ,bdcdpfd.ActiveOpen_Real_Crypto
	  ,bdcdpfd.ActiveOpen_CFD_Crypto
	  ,bdcdpfd.NewTrades_Real_Stocks
	  ,bdcdpfd.NewTrades_CFD_Stocks
	  ,bdcdpfd.NewTrades_Real_Crypto
	  ,bdcdpfd.NewTrades_CFD_Crypto
	  ,bdcdpfd.[NewTrades_FX/Comm/Ind]
	  ,bdcdpfd.NewTrades_Total
	  ,bdcdpfd.AmountIn_NewTrades_Real_Stocks
	  ,bdcdpfd.AmountIn_NewTrades_CFD_Stocks
	  ,bdcdpfd.AmountIn_NewTrades_Real_Crypto
	  ,bdcdpfd.AmountIn_NewTrades_CFD_Crypto
	  ,bdcdpfd.[AmountIn_NewTrades_FX/Comm/Ind]
	  ,bdcdpfd.AmountIn_NewTrades_Total
	  ,bdcdpfd.Revenue_Real_Stocks
	  ,bdcdpfd.Revenue_CFD_Stocks
	  ,bdcdpfd.Revenue_Real_Crypto
	  ,bdcdpfd.Revenue_CFD_Crypto
	  ,bdcdpfd.Revenue_Total
	  ,bdcdpfd.PnL_Real_Stocks
	  ,bdcdpfd.PnL_CFD_Stocks
	  ,bdcdpfd.PnL_Real_Crypto
	  ,bdcdpfd.PnL_CFD_Crypto
	  ,bdcdpfd.PnL_Total
	  ,bdcdpfd.TotalDeposits
	  ,bdcdpfd.CountDeposits
	  ,bdcdpfd.TotalCashouts
	  ,bdcdpfd.TotalCoFee
	  ,bdcdpfd.NetDeposits
	  ,bdcdpfd.AccountManager
	  ,bdcdpfd.EOD_IsFunded
	  ,bdcdpfd.WithdrawalToWallet
	  ,bdcdpfd.IsFunded_New
	  ,bdcdpfd.NewMarketingRegion Region
	  ,dp.PositionID
	  ,dp.Amount OpenAmount
	  ,dp.OpenOccurred
	  ,dp.CloseOccurred
	  ,dp.ParentPositionID
	  ,dp.OrigParentPositionID
	  ,dp.OpenDateID
	  ,dp.CloseDateID
	  ,dp.IsSettled
	  ,dp.AmountInUnitsDecimal
	  ,di.InstrumentType
	  ,di.Name InstrumentName
           ,dp.MirrorID
FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpfd 
LEFT JOIN DWH_dbo.Dim_Position dp 
	ON bdcdpfd.CID = dp.CID
        AND dp.MirrorID=0
	AND ( bdcdpfd.DateID=dp.OpenDateID OR bdcdpfd.DateID=dp.CloseDateID)
JOIN DWH_dbo.Dim_Instrument di 
	ON di.InstrumentID=dp.InstrumentID
WHERE bdcdpfd.DateID>=20240601