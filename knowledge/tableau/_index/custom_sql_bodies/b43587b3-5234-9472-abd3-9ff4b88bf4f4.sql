select 
	DateID
	 , convert(varchar(4),CONVERT(date, convert(varchar(10), ta.DateID)) ,112) AS TimeRange 
	 , Regulation
	 , IsBlocked
	 , IsCreditReportValidCB
	 , IsGermanBaFin
	 , IsValidCustomer
	 , MifidCategory
	 , PlayerLevel
	 , PlayerStatus
	 , FirstActionType
	 , Country
	 , dc.MarketingRegionManualName as Region
	 , isnull(CountUsers						,0) as CountUsers						
	 , isnull(Deposits							,0) as Deposits							
	 , isnull(Bonus								,0) as Bonus								
	 , isnull(Compensation						,0) as Compensation						
	 , isnull(Cashouts							,0) as Cashouts							
	 , isnull(CashoutsIncludingRedeem			,0) as CashoutsIncludingRedeem			
	 , isnull(CashoutFee						,0) as CashoutFee						
	 , isnull(OvernightFee						,0) as OvernightFee						
	 , isnull(CompensationPnLAdjustments		,0) as CompensationPnLAdjustments		
	 , isnull(TransferCoins						,0) as TransferCoins						
	 , isnull(TransferCoinFees					,0) as TransferCoinFees					
	 , isnull(realizedEquity					,0) as realizedEquity					
	 , isnull(DividendsPaid						,0) as DividendsPaid						
	 , isnull(TotalLiability					,0) as TotalLiability					
	 , isnull(InProcessCashout					,0) as InProcessCashout					
	 , isnull(NOPCrypto							,0) as NOPCrypto							
	 , isnull(NOPCryptoCFD						,0) as NOPCryptoCFD						
	 , isnull(NOPStocks							,0) as NOPStocks							
	 , isnull(NOPStocksCFD						,0) as NOPStocksCFD						
	 , isnull(TotalRealCryptoLoan				,0) as TotalRealCryptoLoan				
	 , isnull(PositionPNL						,0) as PositionPNL						
	 , isnull(NOP								,0) as NOP								
	 , isnull(ActualNWA							,0) as ActualNWA							
	 , isnull(UnrealizedPnLChange				,0) as UnrealizedPnLChange				
	 , isnull(DepositsCount						,0) as DepositsCount						
	 , isnull(Deposited							,0) as Deposited							
	 , isnull(CashoutsCount						,0) as CashoutsCount						
	 , isnull(CashoutsAdjusted					,0) as CashoutsAdjusted					
	 , isnull(NewTrades							,0) as NewTrades							
	 , isnull(NumberOfClosedPositions			,0) as NumberOfClosedPositions			
	 , isnull(EditStoplossAmounts				,0) as EditStoplossAmounts				
	 , isnull(TotalInvestmentAmountInNewTrades	,0) as TotalInvestmentAmountInNewTrades	
	 , isnull(FirstDepositors					,0) as FirstDepositors					
	 , isnull(LoggedIn							,0) as LoggedIn							
	 , isnull(FirstDepositAmounts				,0) as FirstDepositAmounts				
	 , isnull(Registrations						,0) as Registrations						
	 , isnull(CashedOut							,0) as CashedOut							
	 , isnull(CompensationRAFInvitedInviting	,0) as CompensationRAFInvitedInviting	
	 , isnull(AccountBalanceToMirrorAmount		,0) as AccountBalanceToMirrorAmount		
	 , isnull(NewCopyAmount						,0) as NewCopyAmount						
	 , isnull(NewCopyActions					,0) as NewCopyActions					
	 , isnull(PublishPost						,0) as PublishPost						
	 , isnull(PublishComment					,0) as PublishComment					
	 , isnull(PublishLike						,0) as PublishLike						
	 , isnull(EngagedInFeed						,0) as EngagedInFeed						
	 , isnull(TotalCommission					,0) as TotalCommission					
	 , isnull(FullTotalCommission				,0) as FullTotalCommission				
	 , isnull(ManualCommission					,0) as ManualCommission					
	 , isnull(CopyCommission					,0) as CopyCommission					
	 , isnull(StocksOnlyCommission				,0) as StocksOnlyCommission				
	 , isnull(ETFCommission						,0) as ETFCommission						
	 , isnull(StocksAndETFsCommission			,0) as StocksAndETFsCommission			
	 , isnull(CurrenciesCommission				,0) as CurrenciesCommission				
	 , isnull(CommoditiesCommission				,0) as CommoditiesCommission				
	 , isnull(IndicesCommission					,0) as IndicesCommission					
	 , isnull(CryptoCommission					,0) as CryptoCommission					
	 , isnull(PnLAdjustment						,0) as PnLAdjustment						
	 , isnull(FullManualCommission				,0) as FullManualCommission				
	 , isnull(FullCopyCommission				,0) as FullCopyCommission				
	 , isnull(FullStocksCommission				,0) as FullStocksCommission				
	 , isnull(FullCryptoCommission				,0) as FullCryptoCommission				
	 , isnull(PnlChange							,0) as PnlChange							
	 , isnull(CopyPnlChange						,0) as CopyPnlChange						
	 , isnull(StocksPnlChange					,0) as StocksPnlChange					
	 , isnull(CryptoPnlChange					,0) as CryptoPnlChange					
	 , isnull(ManualsPnlChange					,0) as ManualsPnlChange					
	 , isnull(ActiveCopy						,0) as ActiveCopy						
	 , isnull(ActiveManualStocksETFs			,0) as ActiveManualStocksETFs			
	 , isnull(ActiveManualFXCommoditiesIndices	,0) as ActiveManualFXCommoditiesIndices	
	 , isnull(ActiveManualCrypto				,0) as ActiveManualCrypto				
	 , isnull(ActiveOpen						,0) as ActiveOpen						
	 , isnull(ActiveOpenManual					,0) as ActiveOpenManual					
	 , isnull(ActiveFunded						,0) as ActiveFunded						
	 , isnull(ActiveTrader						,0) as ActiveTrader						
	 , isnull(Revenue							,0) as Revenue							
	 , isnull(Equity							,0) as Equity							
	 , isnull(NetNewTrades						,0) as NetNewTrades						
	 , isnull(NetDeposit						,0) as NetDeposit						
	 , isnull(AdjustedNetDeposit				,0) as AdjustedNetDeposit				
	 , isnull(OtherCompensationAmount			,0) as OtherCompensationAmount			
	 , isnull(InvestedInManualTradeing			,0) as InvestedInManualTradeing			
	 , isnull(RealizedEquityCalculated			,0) as RealizedEquityCalculated			
	 , isnull(NewCopyNetActions					,0) as NewCopyNetActions					
	 , isnull(NewCopyUniqueUsers				,0) as NewCopyUniqueUsers				
	 , isnull(InvestedInStocksManual			,0) as InvestedInStocksManual			
	 , isnull(InvestedInCryptoManual			,0) as InvestedInCryptoManual			
	 , isnull(InvestedInCopyIncludingCash		,0) as InvestedInCopyIncludingCash		
	 , isnull(NetMoneyIntoCopy					,0) as NetMoneyIntoCopy					
	 , isnull(NetMoneyIntoExistingCopy			,0) as NetMoneyIntoExistingCopy			
	 , isnull(Redeposit							,0) as Redeposit							
	 , isnull(DepositorsLoggedIn				,0) as DepositorsLoggedIn				
	 , isnull(CustomerPnL						,0) as CustomerPnL						
	 , isnull(CustomerPnLStocks					,0) as CustomerPnLStocks					
	 , isnull(CustomerPnLCopy					,0) as CustomerPnLCopy					
	 , isnull(CustomerPnLManual					,0) as CustomerPnLManual					
	 , isnull(CustomerPnLCrypto					,0) as CustomerPnLCrypto					
	 , isnull(CustomerPnLStocksReal				,0) as CustomerPnLStocksReal				
	 , isnull(CustomerPnLCryptoReal				,0) as CustomerPnLCryptoReal				
	 , isnull(FullTotalCommissionFromBreakdown	,0) as FullTotalCommissionFromBreakdown	
	 , isnull(TotalCommissionFromBreakdown		,0) as TotalCommissionFromBreakdown		
	 , isnull(UnrealizedPnL						,0) as UnrealizedPnL						
	 , isnull(CustomerZeroPnL					,0) as CustomerZeroPnL					
	 , isnull(CustomerZeroPnLAdjusted			,0) as CustomerZeroPnLAdjusted			
	 , isnull(CustomerCopyZeroPnL				,0) as CustomerCopyZeroPnL				
	 , isnull(CustomerStocksZeroPnL				,0) as CustomerStocksZeroPnL				
	 , isnull(CustomerPnLAdjusted				,0) as CustomerPnLAdjusted				
	 , isnull(Redeemed							,0) as Redeemed							
	 , isnull(CashedOutDefinition2				,0) as CashedOutDefinition2				
	 , isnull(StockTradersWithProfit			,0) as StockTradersWithProfit			
	 , isnull(StockTradersWithLoss				,0) as StockTradersWithLoss				
	 , isnull(CopyTradersWithProfit				,0) as CopyTradersWithProfit				
	 , isnull(CopyTradersWithLoss				,0) as CopyTradersWithLoss				
	 , isnull(TradersWithProfit					,0) as TradersWithProfit					
	 , isnull(TradersWithLoss					,0) as TradersWithLoss					
	 , isnull(MoneyIntoExistingCopy				,0) as MoneyIntoExistingCopy				
	 , isnull(Credit							,0) as Credit							
	 , isnull(FirstTimeFunded					,0) as FirstTimeFunded					
	 , isnull(Funded_New_Def 					,0) as Funded_New_Def 
	 , isnull(ta.InterestFees 					,0) as InterestFees 
	 , isnull(ConversionFees 					,0) as ConversionFees 
	 , isnull(DormantFee 					,0) as DormantFee
	 , isnull(SDRT 					,0) as SDRT  
from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ta with (nolock)
JOIN DWH_dbo.Dim_Date dd
	ON ta.DateID = dd.DateKey AND dd.IsLastDayOfMonth = 'Y' AND dd.MonthNumberOfYear=12
	AND ta.TimeRange = 'ThisYear'
JOIN DWH_dbo.Dim_Country dc
	ON ta.Country = dc.Name