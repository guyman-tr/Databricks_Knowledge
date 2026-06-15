SELECT 'ThisYear' AS TimeRange
	, bddcl.CID
	, bddcl.DateID
	, bddcl.Regulation
	, bddcl.IsBlocked
	, bddcl.IsCreditReportValidCB
	, bddcl.IsGermanBaFin
	, bddcl.IsValidCustomer
	, bddcl.AccountType
	, bddcl.Country
	, bddcl.[Label]
	, bddcl.MifidCategory
	, bddcl.PlayerLevel
	, bddcl.PlayerStatus
	, bddcl.Region
	, bddcl.IsDepositor
	, bddcl.Deposits
	, bddcl.Bonus
	, bddcl.Compensation
	, bddcl.Cashouts
	, bddcl.CashoutsIncludingRedeem
	, bddcl.CashoutFee
	, bddcl.OvernightFee
	, bddcl.CompensationPnLAdjustments
	, bddcl.TransferCoins
	, bddcl.TransferCoinFees
	, bddcl.realizedEquity
	, bddcl.DividendsPaid
	, bddcl.TotalLiability
	, bddcl.InProcessCashout
	, bddcl.NOPCrypto
	, bddcl.NOPCryptoCFD
	, bddcl.NOPStocks
	, bddcl.NOPStocksCFD
	, bddcl.TotalRealCryptoLoan
	, bddcl.PositionPNL
	, bddcl.NOP
	, bddcl.PositionAmount
	, bddcl.StockOrders
	, bddcl.actualNWA
	, bddcl.UnrealizedPnLChange
	, bddcl.UnrealizedPnLChangeCFD
	, bddcl.UnrealizedPnLChangeCryptoReal
	, bddcl.UnrealizedPnLChangeStocksReal
	, bddcl.DepositsCount
	, bddcl.Deposited
	, bddcl.CompensationRAFInvited
	, bddcl.CompensationRAFInviting
	, bddcl.CompensationOther
	, bddcl.CompensationPIWithCO
	, bddcl.CompensationPINoCO
	, bddcl.CompensationToAffiliateWithCO
	, bddcl.CompensationToAffiliateNoCO
	, bddcl.CashoutsCount
	, bddcl.NewTrades
	, bddcl.NumberOfClosedPositions
	, bddcl.EditStoplossAmounts
	, bddcl.TotalInvestmentAmountInNewTrades
	, bddcl.FirstDepositors
	, bddcl.LoggedIn
	, bddcl.DepositorsLoggedIn
	, bddcl.FirstDepositAmounts
	, bddcl.Registrations
	, bddcl.CashedOut
	, bddcl.Redeemed
	, bddcl.CompensationRAFInvitedInviting
	, bddcl.AccountBalanceToMirrorAmount
	, bddcl.MirrorAmountToAccountBalance
	, bddcl.NewCopyAmount
	, bddcl.StopCopyAmount
	, bddcl.NewCopyActions
	, bddcl.StopCopyActions
	, bddcl.PublishPost
	, bddcl.PublishComment
	, bddcl.PublishLike
	, bddcl.EngagedInFeed
	, bddcl.TotalNetProfit
	, bddcl.ManualNetProfit
	, bddcl.CopyNetProfit
	, bddcl.StocksNetProfit
	, bddcl.StocksRealNetProfit
	, bddcl.CryptoNetProfit
	, bddcl.CryptoRealNetProfit
	, bddcl.TotalCommission
	, bddcl.FullTotalCommission
	, bddcl.ManualCommission
	, bddcl.CopyCommission
	, bddcl.CurrenciesCommission
	, bddcl.CommoditiesCommission
	, bddcl.IndicesCommission
	, bddcl.StocksOnlyCommission
	, bddcl.ETFCommission
	, bddcl.StocksAndETFsCommission
	, bddcl.RealStocksCommission
	, bddcl.CryptoCommission
	, bddcl.PnLAdjustment
	, bddcl.FullManualCommission
	, bddcl.FullCopyCommission
	, bddcl.FullStocksCommission
	, bddcl.FullCryptoCommission
	, bddcl.PnlChange
	, bddcl.CopyPnlChange
	, bddcl.StocksPnlChange
	, bddcl.CryptoPnLChange
	, bddcl.ManualsPnlChange
	, bddcl.StocksRealPnlChange
	, bddcl.CryptoRealPnlChange
	, bddcl.ActiveCopy
	, bddcl.ActiveManualStocksETFs
	, bddcl.ActiveManualFXCommoditiesIndices
	, bddcl.ActiveManualCrypto
	, bddcl.ActiveOpen
	, bddcl.ActiveOpenManual
	, bddcl.ActiveFunded
	, bddcl.ActiveTrader
	, bddcl.FirstDepositDate
	, bddcl.FirstDepositDateID
	, bddcl.PositionID
	, bddcl.ActionTypeID
	, bddcl.FirstActionDateID
	, bddcl.InstrumentTypeID
	, bddcl.MirrorID
	, bddcl.FirstActionType
	, bddcl.Revenue
	, bddcl.Equity
	, bddcl.NetNewTrades
	, bddcl.NetDeposit
	, bddcl.OtherCompensationAmount
	, bddcl.InvestedInManualTradeing
	, bddcl.RealizedEquityCalculated
	, bddcl.NewCopyNetActions
	, bddcl.InvestedInStocksManual
	, bddcl.InvestedInCryptoManual
	, bddcl.InvestedInCopyIncludingCash
	, bddcl.NewCopyUniqueUsers
	, bddcl.NetMoneyIntoExistingCopy
	, bddcl.MoneyIntoExistingCopy
	, bddcl.NetMoneyIntoCopy
	, bddcl.FTDAmountEver
	, bddcl.CustomerPnL
	, bddcl.CustomerPnLStocks
	, bddcl.CustomerPnLCopy
	, bddcl.CustomerPnLManual
	, bddcl.CustomerPnLCrypto
	, bddcl.CustomerPnLStocksReal
	, bddcl.CustomerPnLCryptoReal
	, bddcl.FullTotalCommissionFromBreakdown
	, bddcl.TotalCommissionFromBreakdown
	, bddcl.CashoutsAdjusted
	, bddcl.AdjustedNetDeposit
	, bddcl.UnrealizedPnL
	, bddcl.CustomerZeroPnL
	, bddcl.CustomerZeroPnLAdjusted
	, bddcl.CustomerCopyZeroPnL
	, bddcl.CustomerStocksZeroPnL
	, bddcl.CustomerPnLAdjusted
	, bddcl.Redeposit
	, bddcl.CashedOutDefinition2
	, bddcl.StockTraderWithProfit
	, bddcl.StockTraderWithLoss
	, bddcl.CopyTraderWithProfit
	, bddcl.CopyTraderWithLoss
	, bddcl.TraderWithProfit
	, bddcl.TraderWithLoss
	, bddcl.Credit
	, bddcl.UpdateDate
	, bddcl.FirstTimeFunded
	, bddcl.Funded_New_Def
	, bddcl.FTDCurrentYear
	, bddcl.ReportDate
	, bddcl.ReportDateID
	, b.TotalPeriodCustomerPnL
	, b.TotalPeriodCustomerPnLStocks
	, b.TotalPeriodCustomerPnLCopy
	, b.TotalPeriodCustomerPnLManual
	, b.TotalPeriodCustomerPnLCrypto
	, b.TotalPeriodCustomerPnLStocksReal
	, b.TotalPeriodCustomerPnLCryptoReal
FROM BI_DB_dbo.BI_DB_DDR_CID_Level bddcl
	JOIN (
		  SELECT
			  CID
			, SUM (CustomerPnL)				AS TotalPeriodCustomerPnL
			, SUM (CustomerPnLStocks)		AS TotalPeriodCustomerPnLStocks
			, SUM (CustomerPnLCopy)			AS TotalPeriodCustomerPnLCopy
			, SUM (CustomerPnLManual)		AS TotalPeriodCustomerPnLManual
			, SUM (CustomerPnLCrypto)		AS TotalPeriodCustomerPnLCrypto
			, SUM (CustomerPnLStocksReal)	AS TotalPeriodCustomerPnLStocksReal
			, SUM (CustomerPnLCryptoReal)	AS TotalPeriodCustomerPnLCryptoReal
		  FROM BI_DB_dbo.BI_DB_DDR_CID_Level 
		  WHERE DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(yy, DATEDIFF(yy, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  GROUP BY CID
		) b
			ON b.CID = bddcl.CID 
WHERE bddcl.DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(yy, DATEDIFF(yy, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 



UNION all

SELECT 'Thisquarter' AS TimeRange
	, bddcl.CID
	, bddcl.DateID
	, bddcl.Regulation
	, bddcl.IsBlocked
	, bddcl.IsCreditReportValidCB
	, bddcl.IsGermanBaFin
	, bddcl.IsValidCustomer
	, bddcl.AccountType
	, bddcl.Country
	, bddcl.[Label]
	, bddcl.MifidCategory
	, bddcl.PlayerLevel
	, bddcl.PlayerStatus
	, bddcl.Region
	, bddcl.IsDepositor
	, bddcl.Deposits
	, bddcl.Bonus
	, bddcl.Compensation
	, bddcl.Cashouts
	, bddcl.CashoutsIncludingRedeem
	, bddcl.CashoutFee
	, bddcl.OvernightFee
	, bddcl.CompensationPnLAdjustments
	, bddcl.TransferCoins
	, bddcl.TransferCoinFees
	, bddcl.realizedEquity
	, bddcl.DividendsPaid
	, bddcl.TotalLiability
	, bddcl.InProcessCashout
	, bddcl.NOPCrypto
	, bddcl.NOPCryptoCFD
	, bddcl.NOPStocks
	, bddcl.NOPStocksCFD
	, bddcl.TotalRealCryptoLoan
	, bddcl.PositionPNL
	, bddcl.NOP
	, bddcl.PositionAmount
	, bddcl.StockOrders
	, bddcl.actualNWA
	, bddcl.UnrealizedPnLChange
	, bddcl.UnrealizedPnLChangeCFD
	, bddcl.UnrealizedPnLChangeCryptoReal
	, bddcl.UnrealizedPnLChangeStocksReal
	, bddcl.DepositsCount
	, bddcl.Deposited
	, bddcl.CompensationRAFInvited
	, bddcl.CompensationRAFInviting
	, bddcl.CompensationOther
	, bddcl.CompensationPIWithCO
	, bddcl.CompensationPINoCO
	, bddcl.CompensationToAffiliateWithCO
	, bddcl.CompensationToAffiliateNoCO
	, bddcl.CashoutsCount
	, bddcl.NewTrades
	, bddcl.NumberOfClosedPositions
	, bddcl.EditStoplossAmounts
	, bddcl.TotalInvestmentAmountInNewTrades
	, bddcl.FirstDepositors
	, bddcl.LoggedIn
	, bddcl.DepositorsLoggedIn
	, bddcl.FirstDepositAmounts
	, bddcl.Registrations
	, bddcl.CashedOut
	, bddcl.Redeemed
	, bddcl.CompensationRAFInvitedInviting
	, bddcl.AccountBalanceToMirrorAmount
	, bddcl.MirrorAmountToAccountBalance
	, bddcl.NewCopyAmount
	, bddcl.StopCopyAmount
	, bddcl.NewCopyActions
	, bddcl.StopCopyActions
	, bddcl.PublishPost
	, bddcl.PublishComment
	, bddcl.PublishLike
	, bddcl.EngagedInFeed
	, bddcl.TotalNetProfit
	, bddcl.ManualNetProfit
	, bddcl.CopyNetProfit
	, bddcl.StocksNetProfit
	, bddcl.StocksRealNetProfit
	, bddcl.CryptoNetProfit
	, bddcl.CryptoRealNetProfit
	, bddcl.TotalCommission
	, bddcl.FullTotalCommission
	, bddcl.ManualCommission
	, bddcl.CopyCommission
	, bddcl.CurrenciesCommission
	, bddcl.CommoditiesCommission
	, bddcl.IndicesCommission
	, bddcl.StocksOnlyCommission
	, bddcl.ETFCommission
	, bddcl.StocksAndETFsCommission
	, bddcl.RealStocksCommission
	, bddcl.CryptoCommission
	, bddcl.PnLAdjustment
	, bddcl.FullManualCommission
	, bddcl.FullCopyCommission
	, bddcl.FullStocksCommission
	, bddcl.FullCryptoCommission
	, bddcl.PnlChange
	, bddcl.CopyPnlChange
	, bddcl.StocksPnlChange
	, bddcl.CryptoPnLChange
	, bddcl.ManualsPnlChange
	, bddcl.StocksRealPnlChange
	, bddcl.CryptoRealPnlChange
	, bddcl.ActiveCopy
	, bddcl.ActiveManualStocksETFs
	, bddcl.ActiveManualFXCommoditiesIndices
	, bddcl.ActiveManualCrypto
	, bddcl.ActiveOpen
	, bddcl.ActiveOpenManual
	, bddcl.ActiveFunded
	, bddcl.ActiveTrader
	, bddcl.FirstDepositDate
	, bddcl.FirstDepositDateID
	, bddcl.PositionID
	, bddcl.ActionTypeID
	, bddcl.FirstActionDateID
	, bddcl.InstrumentTypeID
	, bddcl.MirrorID
	, bddcl.FirstActionType
	, bddcl.Revenue
	, bddcl.Equity
	, bddcl.NetNewTrades
	, bddcl.NetDeposit
	, bddcl.OtherCompensationAmount
	, bddcl.InvestedInManualTradeing
	, bddcl.RealizedEquityCalculated
	, bddcl.NewCopyNetActions
	, bddcl.InvestedInStocksManual
	, bddcl.InvestedInCryptoManual
	, bddcl.InvestedInCopyIncludingCash
	, bddcl.NewCopyUniqueUsers
	, bddcl.NetMoneyIntoExistingCopy
	, bddcl.MoneyIntoExistingCopy
	, bddcl.NetMoneyIntoCopy
	, bddcl.FTDAmountEver
	, bddcl.CustomerPnL
	, bddcl.CustomerPnLStocks
	, bddcl.CustomerPnLCopy
	, bddcl.CustomerPnLManual
	, bddcl.CustomerPnLCrypto
	, bddcl.CustomerPnLStocksReal
	, bddcl.CustomerPnLCryptoReal
	, bddcl.FullTotalCommissionFromBreakdown
	, bddcl.TotalCommissionFromBreakdown
	, bddcl.CashoutsAdjusted
	, bddcl.AdjustedNetDeposit
	, bddcl.UnrealizedPnL
	, bddcl.CustomerZeroPnL
	, bddcl.CustomerZeroPnLAdjusted
	, bddcl.CustomerCopyZeroPnL
	, bddcl.CustomerStocksZeroPnL
	, bddcl.CustomerPnLAdjusted
	, bddcl.Redeposit
	, bddcl.CashedOutDefinition2
	, bddcl.StockTraderWithProfit
	, bddcl.StockTraderWithLoss
	, bddcl.CopyTraderWithProfit
	, bddcl.CopyTraderWithLoss
	, bddcl.TraderWithProfit
	, bddcl.TraderWithLoss
	, bddcl.Credit
	, bddcl.UpdateDate
	, bddcl.FirstTimeFunded
	, bddcl.Funded_New_Def
	, bddcl.FTDCurrentYear
	, bddcl.ReportDate
	, bddcl.ReportDateID
	, b.TotalPeriodCustomerPnL
	, b.TotalPeriodCustomerPnLStocks
	, b.TotalPeriodCustomerPnLCopy
	, b.TotalPeriodCustomerPnLManual
	, b.TotalPeriodCustomerPnLCrypto
	, b.TotalPeriodCustomerPnLStocksReal
	, b.TotalPeriodCustomerPnLCryptoReal
FROM BI_DB_dbo.BI_DB_DDR_CID_Level bddcl
	JOIN (
		  SELECT
			  CID
			, SUM (CustomerPnL)				AS TotalPeriodCustomerPnL
			, SUM (CustomerPnLStocks)		AS TotalPeriodCustomerPnLStocks
			, SUM (CustomerPnLCopy)			AS TotalPeriodCustomerPnLCopy
			, SUM (CustomerPnLManual)		AS TotalPeriodCustomerPnLManual
			, SUM (CustomerPnLCrypto)		AS TotalPeriodCustomerPnLCrypto
			, SUM (CustomerPnLStocksReal)	AS TotalPeriodCustomerPnLStocksReal
			, SUM (CustomerPnLCryptoReal)	AS TotalPeriodCustomerPnLCryptoReal
		  FROM BI_DB_dbo.BI_DB_DDR_CID_Level 
		  WHERE DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(qq, DATEDIFF(qq, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  GROUP BY CID
		) b
			ON b.CID = bddcl.CID 
WHERE bddcl.DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(qq, DATEDIFF(qq, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 

UNION all

SELECT 'ThisMonth' AS TimeRange
	, bddcl.CID
	, bddcl.DateID
	, bddcl.Regulation
	, bddcl.IsBlocked
	, bddcl.IsCreditReportValidCB
	, bddcl.IsGermanBaFin
	, bddcl.IsValidCustomer
	, bddcl.AccountType
	, bddcl.Country
	, bddcl.[Label]
	, bddcl.MifidCategory
	, bddcl.PlayerLevel
	, bddcl.PlayerStatus
	, bddcl.Region
	, bddcl.IsDepositor
	, bddcl.Deposits
	, bddcl.Bonus
	, bddcl.Compensation
	, bddcl.Cashouts
	, bddcl.CashoutsIncludingRedeem
	, bddcl.CashoutFee
	, bddcl.OvernightFee
	, bddcl.CompensationPnLAdjustments
	, bddcl.TransferCoins
	, bddcl.TransferCoinFees
	, bddcl.realizedEquity
	, bddcl.DividendsPaid
	, bddcl.TotalLiability
	, bddcl.InProcessCashout
	, bddcl.NOPCrypto
	, bddcl.NOPCryptoCFD
	, bddcl.NOPStocks
	, bddcl.NOPStocksCFD
	, bddcl.TotalRealCryptoLoan
	, bddcl.PositionPNL
	, bddcl.NOP
	, bddcl.PositionAmount
	, bddcl.StockOrders
	, bddcl.actualNWA
	, bddcl.UnrealizedPnLChange
	, bddcl.UnrealizedPnLChangeCFD
	, bddcl.UnrealizedPnLChangeCryptoReal
	, bddcl.UnrealizedPnLChangeStocksReal
	, bddcl.DepositsCount
	, bddcl.Deposited
	, bddcl.CompensationRAFInvited
	, bddcl.CompensationRAFInviting
	, bddcl.CompensationOther
	, bddcl.CompensationPIWithCO
	, bddcl.CompensationPINoCO
	, bddcl.CompensationToAffiliateWithCO
	, bddcl.CompensationToAffiliateNoCO
	, bddcl.CashoutsCount
	, bddcl.NewTrades
	, bddcl.NumberOfClosedPositions
	, bddcl.EditStoplossAmounts
	, bddcl.TotalInvestmentAmountInNewTrades
	, bddcl.FirstDepositors
	, bddcl.LoggedIn
	, bddcl.DepositorsLoggedIn
	, bddcl.FirstDepositAmounts
	, bddcl.Registrations
	, bddcl.CashedOut
	, bddcl.Redeemed
	, bddcl.CompensationRAFInvitedInviting
	, bddcl.AccountBalanceToMirrorAmount
	, bddcl.MirrorAmountToAccountBalance
	, bddcl.NewCopyAmount
	, bddcl.StopCopyAmount
	, bddcl.NewCopyActions
	, bddcl.StopCopyActions
	, bddcl.PublishPost
	, bddcl.PublishComment
	, bddcl.PublishLike
	, bddcl.EngagedInFeed
	, bddcl.TotalNetProfit
	, bddcl.ManualNetProfit
	, bddcl.CopyNetProfit
	, bddcl.StocksNetProfit
	, bddcl.StocksRealNetProfit
	, bddcl.CryptoNetProfit
	, bddcl.CryptoRealNetProfit
	, bddcl.TotalCommission
	, bddcl.FullTotalCommission
	, bddcl.ManualCommission
	, bddcl.CopyCommission
	, bddcl.CurrenciesCommission
	, bddcl.CommoditiesCommission
	, bddcl.IndicesCommission
	, bddcl.StocksOnlyCommission
	, bddcl.ETFCommission
	, bddcl.StocksAndETFsCommission
	, bddcl.RealStocksCommission
	, bddcl.CryptoCommission
	, bddcl.PnLAdjustment
	, bddcl.FullManualCommission
	, bddcl.FullCopyCommission
	, bddcl.FullStocksCommission
	, bddcl.FullCryptoCommission
	, bddcl.PnlChange
	, bddcl.CopyPnlChange
	, bddcl.StocksPnlChange
	, bddcl.CryptoPnLChange
	, bddcl.ManualsPnlChange
	, bddcl.StocksRealPnlChange
	, bddcl.CryptoRealPnlChange
	, bddcl.ActiveCopy
	, bddcl.ActiveManualStocksETFs
	, bddcl.ActiveManualFXCommoditiesIndices
	, bddcl.ActiveManualCrypto
	, bddcl.ActiveOpen
	, bddcl.ActiveOpenManual
	, bddcl.ActiveFunded
	, bddcl.ActiveTrader
	, bddcl.FirstDepositDate
	, bddcl.FirstDepositDateID
	, bddcl.PositionID
	, bddcl.ActionTypeID
	, bddcl.FirstActionDateID
	, bddcl.InstrumentTypeID
	, bddcl.MirrorID
	, bddcl.FirstActionType
	, bddcl.Revenue
	, bddcl.Equity
	, bddcl.NetNewTrades
	, bddcl.NetDeposit
	, bddcl.OtherCompensationAmount
	, bddcl.InvestedInManualTradeing
	, bddcl.RealizedEquityCalculated
	, bddcl.NewCopyNetActions
	, bddcl.InvestedInStocksManual
	, bddcl.InvestedInCryptoManual
	, bddcl.InvestedInCopyIncludingCash
	, bddcl.NewCopyUniqueUsers
	, bddcl.NetMoneyIntoExistingCopy
	, bddcl.MoneyIntoExistingCopy
	, bddcl.NetMoneyIntoCopy
	, bddcl.FTDAmountEver
	, bddcl.CustomerPnL
	, bddcl.CustomerPnLStocks
	, bddcl.CustomerPnLCopy
	, bddcl.CustomerPnLManual
	, bddcl.CustomerPnLCrypto
	, bddcl.CustomerPnLStocksReal
	, bddcl.CustomerPnLCryptoReal
	, bddcl.FullTotalCommissionFromBreakdown
	, bddcl.TotalCommissionFromBreakdown
	, bddcl.CashoutsAdjusted
	, bddcl.AdjustedNetDeposit
	, bddcl.UnrealizedPnL
	, bddcl.CustomerZeroPnL
	, bddcl.CustomerZeroPnLAdjusted
	, bddcl.CustomerCopyZeroPnL
	, bddcl.CustomerStocksZeroPnL
	, bddcl.CustomerPnLAdjusted
	, bddcl.Redeposit
	, bddcl.CashedOutDefinition2
	, bddcl.StockTraderWithProfit
	, bddcl.StockTraderWithLoss
	, bddcl.CopyTraderWithProfit
	, bddcl.CopyTraderWithLoss
	, bddcl.TraderWithProfit
	, bddcl.TraderWithLoss
	, bddcl.Credit
	, bddcl.UpdateDate
	, bddcl.FirstTimeFunded
	, bddcl.Funded_New_Def
	, bddcl.FTDCurrentYear
	, bddcl.ReportDate
	, bddcl.ReportDateID
	, b.TotalPeriodCustomerPnL
	, b.TotalPeriodCustomerPnLStocks
	, b.TotalPeriodCustomerPnLCopy
	, b.TotalPeriodCustomerPnLManual
	, b.TotalPeriodCustomerPnLCrypto
	, b.TotalPeriodCustomerPnLStocksReal
	, b.TotalPeriodCustomerPnLCryptoReal
FROM BI_DB_dbo.BI_DB_DDR_CID_Level bddcl
	JOIN (
		  SELECT
			  CID
			, SUM (CustomerPnL)				AS TotalPeriodCustomerPnL
			, SUM (CustomerPnLStocks)		AS TotalPeriodCustomerPnLStocks
			, SUM (CustomerPnLCopy)			AS TotalPeriodCustomerPnLCopy
			, SUM (CustomerPnLManual)		AS TotalPeriodCustomerPnLManual
			, SUM (CustomerPnLCrypto)		AS TotalPeriodCustomerPnLCrypto
			, SUM (CustomerPnLStocksReal)	AS TotalPeriodCustomerPnLStocksReal
			, SUM (CustomerPnLCryptoReal)	AS TotalPeriodCustomerPnLCryptoReal
		  FROM BI_DB_dbo.BI_DB_DDR_CID_Level 
		  WHERE DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(month, DATEDIFF(mm, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  GROUP BY CID
		) b
			ON b.CID = bddcl.CID 
WHERE bddcl.DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(month, DATEDIFF(mm, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 

UNION all

SELECT 'ThisWeek' AS TimeRange
	, bddcl.CID
	, bddcl.DateID
	, bddcl.Regulation
	, bddcl.IsBlocked
	, bddcl.IsCreditReportValidCB
	, bddcl.IsGermanBaFin
	, bddcl.IsValidCustomer
	, bddcl.AccountType
	, bddcl.Country
	, bddcl.[Label]
	, bddcl.MifidCategory
	, bddcl.PlayerLevel
	, bddcl.PlayerStatus
	, bddcl.Region
	, bddcl.IsDepositor
	, bddcl.Deposits
	, bddcl.Bonus
	, bddcl.Compensation
	, bddcl.Cashouts
	, bddcl.CashoutsIncludingRedeem
	, bddcl.CashoutFee
	, bddcl.OvernightFee
	, bddcl.CompensationPnLAdjustments
	, bddcl.TransferCoins
	, bddcl.TransferCoinFees
	, bddcl.realizedEquity
	, bddcl.DividendsPaid
	, bddcl.TotalLiability
	, bddcl.InProcessCashout
	, bddcl.NOPCrypto
	, bddcl.NOPCryptoCFD
	, bddcl.NOPStocks
	, bddcl.NOPStocksCFD
	, bddcl.TotalRealCryptoLoan
	, bddcl.PositionPNL
	, bddcl.NOP
	, bddcl.PositionAmount
	, bddcl.StockOrders
	, bddcl.actualNWA
	, bddcl.UnrealizedPnLChange
	, bddcl.UnrealizedPnLChangeCFD
	, bddcl.UnrealizedPnLChangeCryptoReal
	, bddcl.UnrealizedPnLChangeStocksReal
	, bddcl.DepositsCount
	, bddcl.Deposited
	, bddcl.CompensationRAFInvited
	, bddcl.CompensationRAFInviting
	, bddcl.CompensationOther
	, bddcl.CompensationPIWithCO
	, bddcl.CompensationPINoCO
	, bddcl.CompensationToAffiliateWithCO
	, bddcl.CompensationToAffiliateNoCO
	, bddcl.CashoutsCount
	, bddcl.NewTrades
	, bddcl.NumberOfClosedPositions
	, bddcl.EditStoplossAmounts
	, bddcl.TotalInvestmentAmountInNewTrades
	, bddcl.FirstDepositors
	, bddcl.LoggedIn
	, bddcl.DepositorsLoggedIn
	, bddcl.FirstDepositAmounts
	, bddcl.Registrations
	, bddcl.CashedOut
	, bddcl.Redeemed
	, bddcl.CompensationRAFInvitedInviting
	, bddcl.AccountBalanceToMirrorAmount
	, bddcl.MirrorAmountToAccountBalance
	, bddcl.NewCopyAmount
	, bddcl.StopCopyAmount
	, bddcl.NewCopyActions
	, bddcl.StopCopyActions
	, bddcl.PublishPost
	, bddcl.PublishComment
	, bddcl.PublishLike
	, bddcl.EngagedInFeed
	, bddcl.TotalNetProfit
	, bddcl.ManualNetProfit
	, bddcl.CopyNetProfit
	, bddcl.StocksNetProfit
	, bddcl.StocksRealNetProfit
	, bddcl.CryptoNetProfit
	, bddcl.CryptoRealNetProfit
	, bddcl.TotalCommission
	, bddcl.FullTotalCommission
	, bddcl.ManualCommission
	, bddcl.CopyCommission
	, bddcl.CurrenciesCommission
	, bddcl.CommoditiesCommission
	, bddcl.IndicesCommission
	, bddcl.StocksOnlyCommission
	, bddcl.ETFCommission
	, bddcl.StocksAndETFsCommission
	, bddcl.RealStocksCommission
	, bddcl.CryptoCommission
	, bddcl.PnLAdjustment
	, bddcl.FullManualCommission
	, bddcl.FullCopyCommission
	, bddcl.FullStocksCommission
	, bddcl.FullCryptoCommission
	, bddcl.PnlChange
	, bddcl.CopyPnlChange
	, bddcl.StocksPnlChange
	, bddcl.CryptoPnLChange
	, bddcl.ManualsPnlChange
	, bddcl.StocksRealPnlChange
	, bddcl.CryptoRealPnlChange
	, bddcl.ActiveCopy
	, bddcl.ActiveManualStocksETFs
	, bddcl.ActiveManualFXCommoditiesIndices
	, bddcl.ActiveManualCrypto
	, bddcl.ActiveOpen
	, bddcl.ActiveOpenManual
	, bddcl.ActiveFunded
	, bddcl.ActiveTrader
	, bddcl.FirstDepositDate
	, bddcl.FirstDepositDateID
	, bddcl.PositionID
	, bddcl.ActionTypeID
	, bddcl.FirstActionDateID
	, bddcl.InstrumentTypeID
	, bddcl.MirrorID
	, bddcl.FirstActionType
	, bddcl.Revenue
	, bddcl.Equity
	, bddcl.NetNewTrades
	, bddcl.NetDeposit
	, bddcl.OtherCompensationAmount
	, bddcl.InvestedInManualTradeing
	, bddcl.RealizedEquityCalculated
	, bddcl.NewCopyNetActions
	, bddcl.InvestedInStocksManual
	, bddcl.InvestedInCryptoManual
	, bddcl.InvestedInCopyIncludingCash
	, bddcl.NewCopyUniqueUsers
	, bddcl.NetMoneyIntoExistingCopy
	, bddcl.MoneyIntoExistingCopy
	, bddcl.NetMoneyIntoCopy
	, bddcl.FTDAmountEver
	, bddcl.CustomerPnL
	, bddcl.CustomerPnLStocks
	, bddcl.CustomerPnLCopy
	, bddcl.CustomerPnLManual
	, bddcl.CustomerPnLCrypto
	, bddcl.CustomerPnLStocksReal
	, bddcl.CustomerPnLCryptoReal
	, bddcl.FullTotalCommissionFromBreakdown
	, bddcl.TotalCommissionFromBreakdown
	, bddcl.CashoutsAdjusted
	, bddcl.AdjustedNetDeposit
	, bddcl.UnrealizedPnL
	, bddcl.CustomerZeroPnL
	, bddcl.CustomerZeroPnLAdjusted
	, bddcl.CustomerCopyZeroPnL
	, bddcl.CustomerStocksZeroPnL
	, bddcl.CustomerPnLAdjusted
	, bddcl.Redeposit
	, bddcl.CashedOutDefinition2
	, bddcl.StockTraderWithProfit
	, bddcl.StockTraderWithLoss
	, bddcl.CopyTraderWithProfit
	, bddcl.CopyTraderWithLoss
	, bddcl.TraderWithProfit
	, bddcl.TraderWithLoss
	, bddcl.Credit
	, bddcl.UpdateDate
	, bddcl.FirstTimeFunded
	, bddcl.Funded_New_Def
	, bddcl.FTDCurrentYear
	, bddcl.ReportDate
	, bddcl.ReportDateID
	, b.TotalPeriodCustomerPnL
	, b.TotalPeriodCustomerPnLStocks
	, b.TotalPeriodCustomerPnLCopy
	, b.TotalPeriodCustomerPnLManual
	, b.TotalPeriodCustomerPnLCrypto
	, b.TotalPeriodCustomerPnLStocksReal
	, b.TotalPeriodCustomerPnLCryptoReal
FROM BI_DB_dbo.BI_DB_DDR_CID_Level bddcl
	JOIN (
		  SELECT
			  CID
			, SUM (CustomerPnL)				AS TotalPeriodCustomerPnL
			, SUM (CustomerPnLStocks)		AS TotalPeriodCustomerPnLStocks
			, SUM (CustomerPnLCopy)			AS TotalPeriodCustomerPnLCopy
			, SUM (CustomerPnLManual)		AS TotalPeriodCustomerPnLManual
			, SUM (CustomerPnLCrypto)		AS TotalPeriodCustomerPnLCrypto
			, SUM (CustomerPnLStocksReal)	AS TotalPeriodCustomerPnLStocksReal
			, SUM (CustomerPnLCryptoReal)	AS TotalPeriodCustomerPnLCryptoReal
		  FROM BI_DB_dbo.BI_DB_DDR_CID_Level 
		  WHERE DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), DATEADD(week, DATEDIFF(ww, 0, <[Parameters].[Parameter 1]>), -1) , 112) AS INT)
		  AND 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  GROUP BY CID
		) b
			ON b.CID = bddcl.CID 
WHERE bddcl.DateID BETWEEN 
CAST(CONVERT(VARCHAR(8), DATEADD(week, DATEDIFF(ww, 0, <[Parameters].[Parameter 1]>), -1) , 112) AS INT)
AND 
CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)

UNION all

SELECT 'Yesterday' AS TimeRange
	, bddcl.CID
	, bddcl.DateID
	, bddcl.Regulation
	, bddcl.IsBlocked
	, bddcl.IsCreditReportValidCB
	, bddcl.IsGermanBaFin
	, bddcl.IsValidCustomer
	, bddcl.AccountType
	, bddcl.Country
	, bddcl.[Label]
	, bddcl.MifidCategory
	, bddcl.PlayerLevel
	, bddcl.PlayerStatus
	, bddcl.Region
	, bddcl.IsDepositor
	, bddcl.Deposits
	, bddcl.Bonus
	, bddcl.Compensation
	, bddcl.Cashouts
	, bddcl.CashoutsIncludingRedeem
	, bddcl.CashoutFee
	, bddcl.OvernightFee
	, bddcl.CompensationPnLAdjustments
	, bddcl.TransferCoins
	, bddcl.TransferCoinFees
	, bddcl.realizedEquity
	, bddcl.DividendsPaid
	, bddcl.TotalLiability
	, bddcl.InProcessCashout
	, bddcl.NOPCrypto
	, bddcl.NOPCryptoCFD
	, bddcl.NOPStocks
	, bddcl.NOPStocksCFD
	, bddcl.TotalRealCryptoLoan
	, bddcl.PositionPNL
	, bddcl.NOP
	, bddcl.PositionAmount
	, bddcl.StockOrders
	, bddcl.actualNWA
	, bddcl.UnrealizedPnLChange
	, bddcl.UnrealizedPnLChangeCFD
	, bddcl.UnrealizedPnLChangeCryptoReal
	, bddcl.UnrealizedPnLChangeStocksReal
	, bddcl.DepositsCount
	, bddcl.Deposited
	, bddcl.CompensationRAFInvited
	, bddcl.CompensationRAFInviting
	, bddcl.CompensationOther
	, bddcl.CompensationPIWithCO
	, bddcl.CompensationPINoCO
	, bddcl.CompensationToAffiliateWithCO
	, bddcl.CompensationToAffiliateNoCO
	, bddcl.CashoutsCount
	, bddcl.NewTrades
	, bddcl.NumberOfClosedPositions
	, bddcl.EditStoplossAmounts
	, bddcl.TotalInvestmentAmountInNewTrades
	, bddcl.FirstDepositors
	, bddcl.LoggedIn
	, bddcl.DepositorsLoggedIn
	, bddcl.FirstDepositAmounts
	, bddcl.Registrations
	, bddcl.CashedOut
	, bddcl.Redeemed
	, bddcl.CompensationRAFInvitedInviting
	, bddcl.AccountBalanceToMirrorAmount
	, bddcl.MirrorAmountToAccountBalance
	, bddcl.NewCopyAmount
	, bddcl.StopCopyAmount
	, bddcl.NewCopyActions
	, bddcl.StopCopyActions
	, bddcl.PublishPost
	, bddcl.PublishComment
	, bddcl.PublishLike
	, bddcl.EngagedInFeed
	, bddcl.TotalNetProfit
	, bddcl.ManualNetProfit
	, bddcl.CopyNetProfit
	, bddcl.StocksNetProfit
	, bddcl.StocksRealNetProfit
	, bddcl.CryptoNetProfit
	, bddcl.CryptoRealNetProfit
	, bddcl.TotalCommission
	, bddcl.FullTotalCommission
	, bddcl.ManualCommission
	, bddcl.CopyCommission
	, bddcl.CurrenciesCommission
	, bddcl.CommoditiesCommission
	, bddcl.IndicesCommission
	, bddcl.StocksOnlyCommission
	, bddcl.ETFCommission
	, bddcl.StocksAndETFsCommission
	, bddcl.RealStocksCommission
	, bddcl.CryptoCommission
	, bddcl.PnLAdjustment
	, bddcl.FullManualCommission
	, bddcl.FullCopyCommission
	, bddcl.FullStocksCommission
	, bddcl.FullCryptoCommission
	, bddcl.PnlChange
	, bddcl.CopyPnlChange
	, bddcl.StocksPnlChange
	, bddcl.CryptoPnLChange
	, bddcl.ManualsPnlChange
	, bddcl.StocksRealPnlChange
	, bddcl.CryptoRealPnlChange
	, bddcl.ActiveCopy
	, bddcl.ActiveManualStocksETFs
	, bddcl.ActiveManualFXCommoditiesIndices
	, bddcl.ActiveManualCrypto
	, bddcl.ActiveOpen
	, bddcl.ActiveOpenManual
	, bddcl.ActiveFunded
	, bddcl.ActiveTrader
	, bddcl.FirstDepositDate
	, bddcl.FirstDepositDateID
	, bddcl.PositionID
	, bddcl.ActionTypeID
	, bddcl.FirstActionDateID
	, bddcl.InstrumentTypeID
	, bddcl.MirrorID
	, bddcl.FirstActionType
	, bddcl.Revenue
	, bddcl.Equity
	, bddcl.NetNewTrades
	, bddcl.NetDeposit
	, bddcl.OtherCompensationAmount
	, bddcl.InvestedInManualTradeing
	, bddcl.RealizedEquityCalculated
	, bddcl.NewCopyNetActions
	, bddcl.InvestedInStocksManual
	, bddcl.InvestedInCryptoManual
	, bddcl.InvestedInCopyIncludingCash
	, bddcl.NewCopyUniqueUsers
	, bddcl.NetMoneyIntoExistingCopy
	, bddcl.MoneyIntoExistingCopy
	, bddcl.NetMoneyIntoCopy
	, bddcl.FTDAmountEver
	, bddcl.CustomerPnL
	, bddcl.CustomerPnLStocks
	, bddcl.CustomerPnLCopy
	, bddcl.CustomerPnLManual
	, bddcl.CustomerPnLCrypto
	, bddcl.CustomerPnLStocksReal
	, bddcl.CustomerPnLCryptoReal
	, bddcl.FullTotalCommissionFromBreakdown
	, bddcl.TotalCommissionFromBreakdown
	, bddcl.CashoutsAdjusted
	, bddcl.AdjustedNetDeposit
	, bddcl.UnrealizedPnL
	, bddcl.CustomerZeroPnL
	, bddcl.CustomerZeroPnLAdjusted
	, bddcl.CustomerCopyZeroPnL
	, bddcl.CustomerStocksZeroPnL
	, bddcl.CustomerPnLAdjusted
	, bddcl.Redeposit
	, bddcl.CashedOutDefinition2
	, bddcl.StockTraderWithProfit
	, bddcl.StockTraderWithLoss
	, bddcl.CopyTraderWithProfit
	, bddcl.CopyTraderWithLoss
	, bddcl.TraderWithProfit
	, bddcl.TraderWithLoss
	, bddcl.Credit
	, bddcl.UpdateDate
	, bddcl.FirstTimeFunded
	, bddcl.Funded_New_Def
	, bddcl.FTDCurrentYear
	, bddcl.ReportDate
	, bddcl.ReportDateID
	, b.TotalPeriodCustomerPnL
	, b.TotalPeriodCustomerPnLStocks
	, b.TotalPeriodCustomerPnLCopy
	, b.TotalPeriodCustomerPnLManual
	, b.TotalPeriodCustomerPnLCrypto
	, b.TotalPeriodCustomerPnLStocksReal
	, b.TotalPeriodCustomerPnLCryptoReal
FROM BI_DB_dbo.BI_DB_DDR_CID_Level bddcl
	JOIN (
		  SELECT
			  CID
			, SUM (CustomerPnL)				AS TotalPeriodCustomerPnL
			, SUM (CustomerPnLStocks)		AS TotalPeriodCustomerPnLStocks
			, SUM (CustomerPnLCopy)			AS TotalPeriodCustomerPnLCopy
			, SUM (CustomerPnLManual)		AS TotalPeriodCustomerPnLManual
			, SUM (CustomerPnLCrypto)		AS TotalPeriodCustomerPnLCrypto
			, SUM (CustomerPnLStocksReal)	AS TotalPeriodCustomerPnLStocksReal
			, SUM (CustomerPnLCryptoReal)	AS TotalPeriodCustomerPnLCryptoReal
		  FROM BI_DB_dbo.BI_DB_DDR_CID_Level 
		  WHERE DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  GROUP BY CID
		) b
			ON b.CID = bddcl.CID 
WHERE bddcl.DateID BETWEEN 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT) 
		  and 
		  CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)