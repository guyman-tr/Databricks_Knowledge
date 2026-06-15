SELECT CID
,TransferDirection
, sum(isnull(ReverseDeposit,0)) as ReverseDeposit 
, sum(isnull(CashoutRollback,0)) as CashoutRollback 
, Regulation
, IsCreditReportValidCB
, DidRegulationTransfer
, DidCBValidTransfer
, IsEtoroTradingCID
, eToroTradingGroupUser
, IsGlenEagleAccount
, Region
, FromRegulation
, ToRegulation
, AccountType
, [Label]
, Country
, MifidCategory
, Club
, PlayerStatus
, DateID
, sum(isnull(OpeningBalance							,0)) as OpeningBalance							
, sum(isnull(Deposits									,0)) as Deposits									
, sum(isnull(CompensationDeposit						,0)) as CompensationDeposit						
, sum(isnull(Bonus										,0)) as Bonus										
, sum(isnull(Compensation								,0)) as Compensation								
, sum(isnull(CompensationPI							,0)) as CompensationPI							
, sum(isnull(CompensationToAffiliate					,0)) as CompensationToAffiliate					
, sum(isnull(NWAAdjustment								,0)) as NWAAdjustment								
, sum(isnull(NegativeRefill							,0)) as NegativeRefill							
, sum(isnull(Cashouts									,0)) as Cashouts									
, sum(isnull(CashoutsIncludingRedeem					,0)) as CashoutsIncludingRedeem					
, sum(isnull(CompensationCashouts						,0)) as CompensationCashouts						
, sum(isnull(CashoutFee								,0)) as CashoutFee								
, sum(isnull(Chargeback								,0)) as Chargeback								
, sum(isnull(Refund									,0)) as Refund									
, sum(isnull(OvernightFee								,0)) as OvernightFee								
, sum(isnull(LostDebt									,0)) as LostDebt									
, sum(isnull(ChargebackLoss							,0)) as ChargebackLoss							
, sum(isnull(OtherNegatives							,0)) as OtherNegatives							
, sum(isnull(Foreclosure								,0)) as Foreclosure								
, sum(isnull(CompensationPnLAdjustments				,0)) as CompensationPnLAdjustments				
, sum(isnull(CompensationDormantFee					,0)) as CompensationDormantFee					
, sum(isnull(ClientBalanceRealizedPnL					,0)) as ClientBalanceRealizedPnL					
, sum(isnull(ClientBalanceRealizedPnLCFD				,0)) as ClientBalanceRealizedPnLCFD				
, sum(isnull(ClientBalanceRealizedPnLRealStocks		,0)) as ClientBalanceRealizedPnLRealStocks		
, sum(isnull(ClientBalanceRealizedPnLRealCrypto		,0)) as ClientBalanceRealizedPnLRealCrypto	
, sum(isnull(ClientBalanceRealizedPnLRealFutures		,0)) as ClientBalanceRealizedPnLRealFutures	
, sum(isnull(TransferCoins								,0)) as TransferCoins								
, sum(isnull(TransferCoinFees							,0)) as TransferCoinFees							
, sum(isnull(ClosingBalance							,0)) as ClosingBalance							
, sum(isnull(realizedEquity							,0)) as realizedEquity							
, sum(isnull(RealCryptoOpenBalance						,0)) as RealCryptoOpenBalance						
, sum(isnull(RealCryptoClosingBalance					,0)) as RealCryptoClosingBalance					
, sum(isnull(ClientMoneyOpenBalance					,0)) as ClientMoneyOpenBalance					
, sum(isnull(ClientMoneyClosingBalance					,0)) as ClientMoneyClosingBalance					
, sum(isnull(RealStocksOpeningBalance					,0)) as RealStocksOpeningBalance	
, sum(isnull(RealFuturesOpenBalance					,0)) as RealFuturesOpenBalance	
, sum(isnull(RealStocksClosingBalance					,0)) as RealStocksClosingBalance
, sum(isnull(RealFuturesClosingBalance					,0)) as RealFuturesClosingBalance
, sum(isnull(ClientBalanceFullCommission				,0)) as ClientBalanceFullCommission				
, sum(isnull(ClientBalanceCommission					,0)) as ClientBalanceCommission					
, sum(isnull(ClientBalanceFullCommissionCFD			,0)) as ClientBalanceFullCommissionCFD			
, sum(isnull(ClientBalanceCommissionCFD				,0)) as ClientBalanceCommissionCFD				
, sum(isnull(ClientBalanceFullCommissionRealCrypto		,0)) as ClientBalanceFullCommissionRealCrypto		
, sum(isnull(ClientBalanceCommissionRealCrypto			,0)) as ClientBalanceCommissionRealCrypto			
, sum(isnull(ClientBalanceFullCommissionRealStocks		,0)) as ClientBalanceFullCommissionRealStocks	
, sum(isnull(ClientBalanceFullCommissionRealFutures		,0)) as ClientBalanceFullCommissionRealFutures	
, sum(isnull(ClientBalanceCommissionRealStocks			,0)) as ClientBalanceCommissionRealStocks	
, sum(isnull(ClientBalanceCommissionRealFutures			,0)) as ClientBalanceCommissionRealFutures	
, sum(isnull(DividendsPaid								,0)) as DividendsPaid								
, sum(isnull(TotalLiability							,0)) as TotalLiability							
, sum(isnull(TotalNegativeLiability					,0)) as TotalNegativeLiability					
, sum(isnull(WithdrawableLiability						,0)) as WithdrawableLiability						
, sum(isnull(NegativeWithdrawableLiability				,0)) as NegativeWithdrawableLiability				
, sum(isnull(LiabilityInUsedMargin						,0)) as LiabilityInUsedMargin						
, sum(isnull(NegativeLiabilityInUsedMargin				,0)) as NegativeLiabilityInUsedMargin				
, sum(isnull(InProcessCashout							,0)) as InProcessCashout							
, sum(isnull(NegativeInProcessCashout					,0)) as NegativeInProcessCashout					
, sum(isnull(NOPCrypto									,0)) as NOPCrypto									
, sum(isnull(NOPCryptoCFD								,0)) as NOPCryptoCFD								
, sum(isnull(NOPStocks									,0)) as NOPStocks
, sum(isnull(NOP_FuturesReal									,0)) as NOP_FuturesReal	
, sum(isnull(NOPStocksCFD								,0)) as NOPStocksCFD								
, sum(isnull(TotalRealCryptoLoan						,0)) as TotalRealCryptoLoan						
, sum(isnull(TotalRealCrypto							,0)) as TotalRealCrypto							
, sum(isnull(TotalRealStocks							,0)) as TotalRealStocks	
, sum(isnull(TotalRealFutures							,0)) as TotalRealFutures	
, sum(isnull(PositionPNLCryptoReal						,0)) as PositionPNLCryptoReal						
, sum(isnull(PositionPNLStocksReal						,0)) as PositionPNLStocksReal	
, sum(isnull(PositionPNLFuturesReal						,0)) as PositionPNLFuturesReal
, sum(isnull(PositionPNL								,0)) as PositionPNL								
, sum(isnull(AvailableCash								,0)) as AvailableCash								
, sum(isnull(CashInCopy								,0)) as CashInCopy								
, sum(isnull(NOP										,0)) as NOP										
, sum(isnull(PositionAmount							,0)) as PositionAmount							
, sum(isnull(StockOrders								,0)) as StockOrders								
, sum(isnull(actualNWA									,0)) as actualNWA									
, sum(isnull(UsedBonus									,0)) as UsedBonus									
, sum(isnull(UnrealizedCommissionChange				,0)) as UnrealizedCommissionChange				
, sum(isnull(UnrealizedFullCommissionChange			,0)) as UnrealizedFullCommissionChange			
, sum(isnull(UnrealizedPnLChange						,0)) as UnrealizedPnLChange						
, sum(isnull(UnrealizedPnLChangeCFD					,0)) as UnrealizedPnLChangeCFD					
, sum(isnull(UnrealizedPnLChangeCryptoReal				,0)) as UnrealizedPnLChangeCryptoReal				
, sum(isnull(UnrealizedPnLChangeStocksReal				,0)) as UnrealizedPnLChangeStocksReal		
, sum(isnull(UnrealizedPnLChangeFuturesReal				,0)) as UnrealizedPnLChangeFuturesReal	
, sum(isnull(UnrealizedFullCommissionChangeRealStocks	,0)) as UnrealizedFullCommissionChangeRealStocks	
, sum(isnull(UnrealizedFullCommissionChangeRealFutures	,0)) as UnrealizedFullCommissionChangeRealFutures	
, sum(isnull(TotalNetTransfers							,0)) as TotalNetTransfers							
, sum(isnull(TotalTransfersInvestedRealStocks			,0)) as TotalTransfersInvestedRealStocks	
, sum(isnull(TotalTransfersInvestedRealFutures			,0)) as TotalTransfersInvestedRealFutures
, sum(isnull(TotalTransfersInvestedRealCrypto			,0)) as TotalTransfersInvestedRealCrypto			
, sum(isnull(NetTransfersNWA							,0)) as NetTransfersNWA							
, sum(isnull(NetTransfersUnrealizedPnL					,0)) as NetTransfersUnrealizedPnL					
, sum(isnull(NetTransfersLiability						,0)) as NetTransfersLiability						
, sum(isnull(NetLiabilityTransferStocks				,0)) as NetLiabilityTransferStocks	
, sum(isnull(NetTransfersLiabilityFuturesReal				,0)) as NetTransfersLiabilityFuturesReal				
, sum(isnull(NetUnrealizedPnLTransferStocks			,0)) as NetUnrealizedPnLTransferStocks		
, sum(isnull(NetTransfersUnrealizedPnLFuturesReal			,0)) as NetTransfersUnrealizedPnLFuturesReal	
, sum(isnull(PositionPnLCrypto							,0)) as PositionPnLCrypto							
, sum(isnull(PositionPnLStocks							,0)) as PositionPnLStocks							
, sum(isnull(TotalCryptoPositionAmount					,0)) as TotalCryptoPositionAmount					
, sum(isnull(TotalStocksPositionAmount	,0)) as TotalStocksPositionAmount
, sum(isnull(TotalStockMarginLoanValue	,0)) as TotalStockMarginLoanValue	
, sum(UnrealizedCommissionChangeRealStocks) UnrealizedCommissionChangeRealStocks
, sum(UnrealizedCommissionChangeRealFutures) UnrealizedCommissionChangeRealFutures
, sum(TotalRealStocksEquityChange) TotalRealStocksEquityChange
, sum(TotalRealFuturesEquityChange) TotalRealFuturesEquityChange
, IsGermanBaFin
, IsValidCustomer
, Date
, YearMonth
, YearQuarter
, Year
, CASE
WHEN [Label] IN ('eToro','eToro-Partners','eToroChina','eToroRussia','eToroUSA','etoro-raf')
THEN 'eToro AUS'
ELSE
	CASE
	WHEN [Label] in ( 'ICMarkets','ICM','Other')
	THEN 'ICM'
	ELSE 'Other'
	END 
END LabelType
, CASE
WHEN ISNULL(Deposits,0) <> 0
THEN 'Yes'
ELSE 'No'
END  AS [Deposit<>0]
, IsDLTUser
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New with (nolock)
WHERE DateID = /*20250128 --*/ CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[Parameter 1 1]> as DATE), 112) AS INT) 
and CID = /*3870926 --*/ <[Parameters].[Parameter 7]>
GROUP BY 
CID
, TransferDirection
, Regulation
, IsCreditReportValidCB
, DidRegulationTransfer
, DidCBValidTransfer
, IsEtoroTradingCID
, eToroTradingGroupUser
, IsGlenEagleAccount
, Region
, FromRegulation
, ToRegulation
, AccountType
, [Label]
, Country
, MifidCategory
, Club
, PlayerStatus
, DateID
, IsGermanBaFin
, IsValidCustomer
, Date
, YearMonth
, YearQuarter
, Year
, CASE
WHEN [Label] IN ('eToro','eToro-Partners','eToroChina','eToroRussia','eToroUSA','etoro-raf')
THEN 'eToro AUS'
ELSE
	CASE
	WHEN [Label] in ( 'ICMarkets','ICM','Other')
	THEN 'ICM'
	ELSE 'Other'
	END 
END 
, CASE
WHEN ISNULL(Deposits,0) <> 0
THEN 'Yes'
ELSE 'No'
END
, IsDLTUser