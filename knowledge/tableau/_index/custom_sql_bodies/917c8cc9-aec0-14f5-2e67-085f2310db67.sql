SELECT a.TransferDirection
	 , a.Regulation
	 , a.IsCreditReportValidCB
	 , a.DidRegulationTransfer
	 , a.DidCBValidTransfer
	 , a.IsEtoroTradingCID
	 , a.eToroTradingGroupUser
	 , a.IsGlenEagleAccount
	 , a.Region
	 , a.FromRegulation
	 , a.ToRegulation
	 , a.AccountType
	 , a.[Label]
	 , a.Country
	 , a.MifidCategory
	 , a.Club
	 , a.PlayerStatus
	 , a.DateID
	 , CASE WHEN a.RNAsc = 1 THEN a.OpeningBalance ELSE 0 END AS OpeningBalance
	 , a.Deposits
	 , a.CompensationDeposit
	 , a.Bonus
	 , a.Compensation
	 , a.CompensationPI
	 , a.CompensationToAffiliate
	 , a.NWAAdjustment
	 , a.NegativeRefill
	 , a.Cashouts
	 , a.CashoutsIncludingRedeem
	 , a.CompensationCashouts
	 , a.CashoutFee
	 , a.Chargeback
	 , a.Refund
	 , a.OvernightFee
	 , a.LostDebt
	 , a.ChargebackLoss
	 , a.OtherNegatives
	 , a.Foreclosure
	 , a.CompensationPnLAdjustments
	 , a.CompensationDormantFee
	 , a.ClientBalanceRealizedPnL
	 , a.ClientBalanceRealizedPnLCFD
	 , a.ClientBalanceRealizedPnLRealStocks
	 , a.ClientBalanceRealizedPnLRealCrypto
	 , a.TransferCoins
	 , a.TransferCoinFees
	 , CASE WHEN RNDesc = 1 THEN  a.ClosingBalance ELSE 0 END AS ClosingBalance
	 , a.realizedEquity
	 , CASE WHEN a.RNAsc = 1 THEN a.RealCryptoOpenBalance ELSE 0 END AS RealCryptoOpenBalance
	 , CASE WHEN a.RNDesc = 1 THEN  a.RealCryptoClosingBalance ELSE 0 END AS RealCryptoClosingBalance
	 , CASE WHEN a.RNAsc = 1 THEN a.ClientMoneyOpenBalance ELSE 0 END AS ClientMoneyOpenBalance
	 , CASE WHEN a.RNDesc = 1 THEN  a.ClientMoneyClosingBalance ELSE 0 END AS ClientMoneyClosingBalance
	 , CASE WHEN a.RNAsc = 1 THEN a.RealStocksOpeningBalance ELSE 0 END AS RealStocksOpeningBalance
	 , CASE WHEN a.RNDesc = 1 THEN  a.RealStocksClosingBalance ELSE 0 END AS RealStocksClosingBalance
	 , a.ClientBalanceFullCommission
	 , a.ClientBalanceCommission
	 , a.ClientBalanceFullCommissionCFD
	 , a.ClientBalanceCommissionCFD
	 , a.ClientBalanceFullCommissionRealCrypto
	 , a.ClientBalanceCommissionRealCrypto
	 , a.ClientBalanceFullCommissionRealStocks
	 , a.ClientBalanceCommissionRealStocks
	 , a.DividendsPaid
	 , a.SDRT
	 , a.TicketFee
	 , a.TicketFeeByPercent
	 , a.TotalLiability
	 , a.TotalNegativeLiability
	 , a.WithdrawableLiability
	 , a.NegativeWithdrawableLiability
	 , a.LiabilityInUsedMargin
	 , a.NegativeLiabilityInUsedMargin
	 , a.InProcessCashout
	 , a.NegativeInProcessCashout
	 , a.NOPCrypto --
	 , a.NOPCryptoCFD --
	 , a.NOPStocks -- 
	 , a.NOPStocksCFD --
	 , a.TotalRealCryptoLoan --
	 , a.TotalRealCrypto --
	 , a.TotalRealStocks --
	 , a.PositionPNLCryptoReal --
	 , a.PositionPNLStocksReal --
	 , a.PositionPNL --
	 , a.AvailableCash --
	 , a.CashInCopy --
	 , a.NOP --
	 , a.PositionAmount --
	 , a.StockOrders --
	 , a.actualNWA --
	 , a.UsedBonus
	 , a.UnrealizedCommissionChange
	 , a.UnrealizedFullCommissionChange
	 , a.UnrealizedPnLChange
	 , a.UnrealizedPnLChangeCFD
	 , a.UnrealizedPnLChangeCryptoReal
	 , a.UnrealizedPnLChangeStocksReal
	 , a.UnrealizedFullCommissionChangeRealStocks
	 , a.TotalNetTransfers
	 , a.TotalTransfersInvestedRealStocks
	 , a.TotalTransfersInvestedRealCrypto
	 , a.NetTransfersNWA
	 , a.NetTransfersUnrealizedPnL
	 , a.NetTransfersLiability
	 , a.NetLiabilityTransferStocks
	 , a.NetUnrealizedPnLTransferStocks
	 , a.UpdateDate
	 , a.PositionPnLCrypto --
	 , a.PositionPnLStocks --
	 , a.TotalCryptoPositionAmount --
	 , a.TotalStocksPositionAmount --
	 , a.IsGermanBaFin
	 , a.IsValidCustomer
	 , a.Date
	 , a.YearMonth
	 , a.YearQuarter
	 , a.Year
	 , a.RNAsc
	 , a.RNDesc
     , a.UnrealizedCommissionChangeRealStocks
     , a.TotalRealStocksEquityChange 
	 , a.CompensationsApexUSStocks
	 , EquityRealStocks --
	 , EquityRealCrypto --
	 , EquityRealFutures --
	 , Equity --
	 , EquityCFD --
	 , TotalCash --
	 , CASE WHEN a.RNAsc = 1 THEN a.OpeningBalanceAdjusted ELSE 0 END AS OpeningBalanceAdjusted
	 , CompensationAdjusted
	 , ClientBalanceRealizedPnLAdjusted
	 , ClientBalanceRealizedPnLRealStocksAdjusted
	 , CASE WHEN a.RNDesc = 1 THEN  a.ClosingBalanceAdjusted ELSE 0 END AS ClosingBalanceAdjusted
	 , CASE WHEN a.RNAsc = 1 THEN a.RealStocksOpeningBalanceAdjusted ELSE 0 END AS RealStocksOpeningBalanceAdjusted
	 , CASE WHEN a.RNDesc = 1 THEN  a.RealStocksClosingBalanceAdjusted ELSE 0 END AS RealStocksClosingBalanceAdjusted
	 , ClientBalanceFullCommissionAdjusted
	 , ClientBalanceCommissionAdjusted
	 , ClientBalanceFullCommissionRealStocksAdjusted
	 , ClientBalanceCommissionRealStocksAdjusted
	 , NOPStocksAdjusted --
	 , NOPStocksCFDAdjusted --
	 , TotalRealStocksAdjusted --
	 , PositionPNLStocksRealAdjusted --
	 , PositionPNLAdjusted --
	 , NOPAdjusted --
	 , PositionAmountAdjusted --
	 , StockOrdersAdjusted --
	 , UnrealizedCommissionChangeAdjusted
	 , UnrealizedFullCommissionChangeAdjusted
	 , UnrealizedPnLChangeAdjusted
	 , UnrealizedPnLChangeStocksRealAdjusted
	 , UnrealizedFullCommissionChangeRealStocksAdjusted
	 , PositionPnLStocksAdjusted --
	 , TotalStocksPositionAmountAdjusted
	 , UnrealizedCommissionChangeRealStocksAdjusted
	 , TotalRealStocksEquityChangeAdjusted
	 , EquityRealStocksAdjusted --
	 , RealStockInvestedAmountChangeAdjusted
	 , RealStocksAdjusted --
	 , CashoutRollback
	 , ReverseDeposit
	 , DepositConversionFee
	 , WithdrawConversionFee
	 , a.IsDLTUser
-- INTO #temp
FROM 
(
select TransferDirection
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
	 , OpeningBalance 
	 , CASE WHEN Regulation = 'FinCEN+FINRA' then ISNULL(OpeningBalance,0) - ISNULL(RealStocksOpeningBalance,0) ELSE ISNULL(OpeningBalance,0) END AS OpeningBalanceAdjusted
	 , Deposits
	 , CompensationDeposit
	 , Bonus
	 , Compensation
	 , CASE WHEN Regulation = 'FinCEN+FINRA' then ISNULL(Compensation,0) - ISNULL(CompensationsApexUSStocks,0) ELSE ISNULL(Compensation,0) END AS CompensationAdjusted
	 , CompensationPI
	 , CompensationToAffiliate
	 , NWAAdjustment
	 , NegativeRefill
	 , Cashouts
	 , CashoutsIncludingRedeem
	 , CompensationCashouts
	 , CashoutFee
	 , Chargeback
	 , Refund
	 , OvernightFee
	 , LostDebt
	 , ChargebackLoss
	 , OtherNegatives
	 , Foreclosure
	 , CompensationPnLAdjustments
	 , CompensationDormantFee
	 , ClientBalanceRealizedPnL
	 , CASE WHEN Regulation = 'FinCEN+FINRA' then ISNULL(ClientBalanceRealizedPnL,0) - ISNULL(ClientBalanceRealizedPnLRealStocks,0) ELSE ISNULL(ClientBalanceRealizedPnL,0) END AS ClientBalanceRealizedPnLAdjusted
	 , ClientBalanceRealizedPnLCFD
	 , ClientBalanceRealizedPnLRealStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' then 0  ELSE ISNULL(ClientBalanceRealizedPnLRealStocks,0) END AS ClientBalanceRealizedPnLRealStocksAdjusted
	 , ClientBalanceRealizedPnLRealCrypto
	 , TransferCoins
	 , TransferCoinFees
	 , ClosingBalance
	 ,  CASE WHEN Regulation = 'FinCEN+FINRA' then ISNULL(ClosingBalance,0) - ISNULL(RealStocksClosingBalance,0) ELSE ISNULL(ClosingBalance,0) END AS ClosingBalanceAdjusted
	 , realizedEquity
	 , RealCryptoOpenBalance
	 , RealCryptoClosingBalance
	 , ClientMoneyOpenBalance
	 , ClientMoneyClosingBalance
	 , RealStocksOpeningBalance
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE RealStocksOpeningBalance END AS RealStocksOpeningBalanceAdjusted
	 , RealStocksClosingBalance
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE RealStocksClosingBalance END AS RealStocksClosingBalanceAdjusted
	 , ClientBalanceFullCommission
	 , CASE WHEN Regulation = 'FinCEN+FINRA' AND Regulation <> FromRegulation then ISNULL(ClientBalanceFullCommission,0) - ISNULL(ClientBalanceFullCommissionRealStocks,0) ELSE ISNULL(ClientBalanceFullCommission,0) END AS ClientBalanceFullCommissionAdjusted
	 , ClientBalanceCommission
	 , CASE WHEN Regulation = 'FinCEN+FINRA' AND Regulation <> FromRegulation then ISNULL(ClientBalanceCommission,0) - ISNULL(ClientBalanceCommissionRealStocks,0) ELSE ISNULL(ClientBalanceCommission,0) END AS ClientBalanceCommissionAdjusted
	 , ClientBalanceFullCommissionCFD
	 , ClientBalanceCommissionCFD
	 , ClientBalanceFullCommissionRealCrypto
	 , ClientBalanceCommissionRealCrypto
	 , ClientBalanceFullCommissionRealStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE ClientBalanceFullCommissionRealStocks end  AS ClientBalanceFullCommissionRealStocksAdjusted
	 , ClientBalanceCommissionRealStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE ClientBalanceCommissionRealStocks END AS ClientBalanceCommissionRealStocksAdjusted
	 , DividendsPaid
	 , SDRT
	 , TicketFee
	 , TicketFeeByPercent
	 , TotalLiability
	 , TotalNegativeLiability
	 , WithdrawableLiability
	 , NegativeWithdrawableLiability
	 , LiabilityInUsedMargin
	 , NegativeLiabilityInUsedMargin
	 , InProcessCashout
	 , NegativeInProcessCashout
	 , NOPCrypto
	 , NOPCryptoCFD
	 , NOPStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE NOPStocks END AS NOPStocksAdjusted
	 , NOPStocksCFD
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE NOPStocksCFD END AS NOPStocksCFDAdjusted
	 , TotalRealCryptoLoan
	 , TotalRealCrypto
	 , TotalRealStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE TotalRealStocks END AS TotalRealStocksAdjusted
	 , PositionPNLCryptoReal
	 , PositionPNLStocksReal
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE PositionPNLStocksReal END AS PositionPNLStocksRealAdjusted
	 , PositionPNL
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(PositionPNL,0) - ISNULL(PositionPNLStocksReal,0) ELSE ISNULL(PositionPNL,0) END AS PositionPNLAdjusted
	 , AvailableCash
	 , CashInCopy
	 , NOP
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(NOP,0) - ISNULL(NOPStocks,0) ELSE ISNULL(NOP,0) END AS NOPAdjusted
	 , PositionAmount
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(PositionAmount,0) - ISNULL(TotalStocksPositionAmount,0) ELSE ISNULL(PositionAmount,0) END AS PositionAmountAdjusted
	 , StockOrders
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE StockOrders END AS StockOrdersAdjusted
	 , actualNWA
	 , UsedBonus
	 , UnrealizedCommissionChange
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(UnrealizedCommissionChange,0) - ISNULL(UnrealizedCommissionChangeRealStocks,0) ELSE ISNULL(UnrealizedCommissionChange,0) END AS UnrealizedCommissionChangeAdjusted
	 , UnrealizedFullCommissionChange
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(UnrealizedFullCommissionChange,0) - ISNULL(UnrealizedFullCommissionChangeRealStocks,0) ELSE ISNULL(UnrealizedFullCommissionChange,0) END AS UnrealizedFullCommissionChangeAdjusted
	 , UnrealizedPnLChange
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN ISNULL(UnrealizedPnLChange,0) - ISNULL(UnrealizedPnLChangeStocksReal,0) ELSE ISNULL(UnrealizedPnLChange,0) END AS UnrealizedPnLChangeAdjusted
	 , UnrealizedPnLChangeCFD
	 , UnrealizedPnLChangeCryptoReal
	 , UnrealizedPnLChangeStocksReal
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE UnrealizedPnLChangeStocksReal END AS UnrealizedPnLChangeStocksRealAdjusted
	 , UnrealizedFullCommissionChangeRealStocks
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE UnrealizedFullCommissionChangeRealStocks END AS UnrealizedFullCommissionChangeRealStocksAdjusted
	 , TotalNetTransfers
	 , TotalTransfersInvestedRealStocks
	 , TotalTransfersInvestedRealCrypto
	 , NetTransfersNWA
	 , NetTransfersUnrealizedPnL
	 , NetTransfersLiability
	 , NetLiabilityTransferStocks
	 , NetUnrealizedPnLTransferStocks
	 , UpdateDate
	 , PositionPnLCrypto
	 , PositionPnLStocks 
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE PositionPnLStocks END AS PositionPnLStocksAdjusted
	 , TotalCryptoPositionAmount
	 , TotalStocksPositionAmount
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE TotalStocksPositionAmount END AS TotalStocksPositionAmountAdjusted
	 , IsGermanBaFin
	 , IsValidCustomer
	 , Date
	 , YearMonth
	 , YearQuarter
	 , Year
	 , DENSE_RANK () OVER (ORDER BY DateID) AS RNAsc
	 , DENSE_RANK () OVER (ORDER BY DateID desc) AS RNDesc
     , UnrealizedCommissionChangeRealStocks
     , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE UnrealizedCommissionChangeRealStocks END AS UnrealizedCommissionChangeRealStocksAdjusted
     , TotalRealStocksEquityChange
     , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE TotalRealStocksEquityChange END AS TotalRealStocksEquityChangeAdjusted
	 , CompensationsApexUSStocks
	 , ISNULL(TotalRealStocks,0) + ISNULL(PositionPNLStocksReal,0) as EquityRealStocks
	 , ISNULL(TotalRealCrypto,0) + ISNULL(PositionPNLCryptoReal,0) as EquityRealCrypto
	 , ISNULL(TotalRealFutures,0) + ISNULL(PositionPNLFuturesReal,0) as EquityRealFutures
	 , ISNULL(PositionAmount,0) + ISNULL(PositionPNL,0) AS Equity
	 , ISNULL(PositionAmount,0) + ISNULL(PositionPNL,0) 
			- (ISNULL(TotalRealStocks,0) + ISNULL(PositionPNLStocksReal,0)) 
			- (ISNULL(TotalRealCrypto,0) + ISNULL(PositionPNLCryptoReal,0)) 
			- (ISNULL(TotalRealFutures,0) + ISNULL(PositionPNLFuturesReal,0)) 			
			AS EquityCFD
	 , ISNULL(CashInCopy,0) + ISNULL(AvailableCash,0) AS TotalCash
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE TotalRealStocks + PositionPNLStocksReal end as EquityRealStocksAdjusted
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN -1 * (ISNULL(TotalRealStocksEquityChange,0) - ISNULL(UnrealizedPnLChangeStocksReal,0) - ISNULL(ClientBalanceRealizedPnLRealStocks,0)) ELSE 0 END as RealStockInvestedAmountChangeAdjusted
	 , CASE WHEN Regulation = 'FinCEN+FINRA' THEN 0 ELSE [RealStocksClosingBalance] END as RealStocksAdjusted
	 , CashoutRollback
	 , ReverseDeposit
	 , DepositConversionFee
	 , WithdrawConversionFee
	 , IsDLTUser
from BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New  with (nolock)
where DateID between -- 20250622 AND 20250622
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy)]> as DATE), 112) AS INT)
and 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy 2)]> as DATE), 112) AS INT)
) a