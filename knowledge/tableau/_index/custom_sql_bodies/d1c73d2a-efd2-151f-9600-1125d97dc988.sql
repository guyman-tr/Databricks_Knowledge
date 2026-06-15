select tr.DateID
	 , tr.TimeRange
	 , tr.Regulation
	 , tr.IsBlocked
	 , tr.IsCreditReportValidCB
	 , tr.IsGermanBaFin
	 , tr.IsValidCustomer
	 , tr.MifidCategory
	 , tr.PlayerLevel
	 , tr.PlayerStatus
	 , tr.FirstActionType
	 , tr.Country
	 , dc.MarketingRegionManualName as Region
	 , tr.CountUsers
	 , tr.Deposits
	 , tr.Bonus
	 , tr.Compensation
	 , tr.Cashouts
	 , tr.CashoutsIncludingRedeem
	 , tr.CashoutFee
	 , tr.OvernightFee
	 , tr.CompensationPnLAdjustments
	 , tr.TransferCoins
	 , tr.TransferCoinFees
	 , tr.realizedEquity
	 , tr.DividendsPaid
	 , tr.TotalLiability
	 , tr.InProcessCashout
	 , tr.NOPCrypto
	 , tr.NOPCryptoCFD
	 , tr.NOPStocks
	 , tr.NOPStocksCFD
	 , tr.TotalRealCryptoLoan
	 , tr.PositionPNL
	 , tr.NOP
	 , tr.ActualNWA
	 , tr.UnrealizedPnLChange
	 , tr.DepositsCount
	 , tr.Deposited
	 , tr.CashoutsCount
	 , tr.CashoutsAdjusted
	 , tr.NewTrades
	 , tr.NumberOfClosedPositions
	 , tr.EditStoplossAmounts
	 , tr.TotalInvestmentAmountInNewTrades
	 , tr.FirstDepositors
	 , tr.LoggedIn
	 , tr.FirstDepositAmounts
	 , tr.Registrations
	 , tr.CashedOut
	 , tr.CompensationRAFInvitedInviting
	 , tr.AccountBalanceToMirrorAmount
	 , tr.NewCopyAmount
	 , tr.NewCopyActions
	 , tr.PublishPost
	 , tr.PublishComment
	 , tr.PublishLike
	 , tr.EngagedInFeed
	 , tr.TotalCommission
	 , tr.FullTotalCommission
	 , tr.ManualCommission
	 , tr.CopyCommission
	 , tr.StocksOnlyCommission
	 , tr.ETFCommission
	 , tr.StocksAndETFsCommission
	 , tr.CurrenciesCommission
	 , tr.CommoditiesCommission
	 , tr.IndicesCommission
	 , tr.CryptoCommission
	 , tr.PnLAdjustment
	 , tr.FullManualCommission
	 , tr.FullCopyCommission
	 , tr.FullStocksCommission
	 , tr.FullCryptoCommission
	 , tr.PnlChange
	 , tr.CopyPnlChange
	 , tr.StocksPnlChange
	 , tr.CryptoPnlChange
	 , tr.ManualsPnlChange
	 , tr.ActiveCopy
	 , tr.ActiveManualStocksETFs
	 , tr.ActiveManualFXCommoditiesIndices
	 , tr.ActiveManualCrypto
	 , tr.ActiveOpen
	 , tr.ActiveOpenManual
	 , tr.ActiveFunded
	 , tr.ActiveTrader
	 , tr.Revenue
	 , tr.Equity
	 , tr.NetNewTrades
	 , tr.NetDeposit
	 , tr.AdjustedNetDeposit
	 , tr.OtherCompensationAmount
	 , tr.InvestedInManualTradeing
	 , tr.RealizedEquityCalculated
	 , tr.NewCopyNetActions
	 , tr.NewCopyUniqueUsers
	 , tr.InvestedInStocksManual
	 , tr.InvestedInCryptoManual
	 , tr.InvestedInCopyIncludingCash
	 , tr.NetMoneyIntoCopy
	 , tr.NetMoneyIntoExistingCopy
	 , tr.Redeposit
	 , tr.DepositorsLoggedIn
	 , tr.CustomerPnL
	 , tr.CustomerPnLStocks
	 , tr.CustomerPnLCopy
	 , tr.CustomerPnLManual
	 , tr.CustomerPnLCrypto
	 , tr.CustomerPnLStocksReal
	 , tr.CustomerPnLCryptoReal
	 , tr.FullTotalCommissionFromBreakdown
	 , tr.TotalCommissionFromBreakdown
	 , tr.UnrealizedPnL
	 , tr.CustomerZeroPnL
	 , tr.CustomerZeroPnLAdjusted
	 , tr.CustomerCopyZeroPnL
	 , tr.CustomerStocksZeroPnL
	 , tr.CustomerPnLAdjusted
	 , tr.Redeemed
	 , tr.CashedOutDefinition2
	 , tr.StockTradersWithProfit
	 , tr.StockTradersWithLoss
	 , tr.CopyTradersWithProfit
	 , tr.CopyTradersWithLoss
	 , tr.TradersWithProfit
	 , tr.TradersWithLoss
	 , tr.MoneyIntoExistingCopy
	 , tr.Credit
	 , tr.UpdateDate
	 , tr.FirstTimeFunded
	 , tr.Funded_New_Def
	 , tr.FTDCurrentYear
	 , tr.ReportDate
	 , tr.ReportDateID
	 , tr.DormantFee
	 , tr.ConversionFees
	 , tr.WalletBalanceUSD
	 , tr.InterestFees
	 , tr.DataSource
	 , tr.InvestedInCryptoTRS
     , -1 * SDRT as SDRT
	 ,-1*tr.TradingFees as TradingFees
	 ,-1*tr.TicketFees as TicketFees
from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] tr with (nolock)
JOIN DWH_dbo.Dim_Country dc WITH (NOLOCK)
	ON tr.Country = dc.Name
where DateID = CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)