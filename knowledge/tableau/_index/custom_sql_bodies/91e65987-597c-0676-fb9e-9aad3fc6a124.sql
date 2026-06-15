SELECT
	 bdcbcln.CID
        , CONVERT(date, convert(varchar(10), bdcbcln.DateID)) as Date
	, bdcbcln.IsCreditReportValidCB
	, bdcbcln.Regulation
	, bdcbcln.DidCBValidTransfer
	, bdcbcln.TransferDirection
	, bdcbcln.DidRegulationTransfer
        , FromRegulation
        , ToRegulation
	,isnull(TotalRealCrypto		,0)	+ 
	isnull(PositionPNLCryptoReal,0)	+ 
	isnull(TotalRealStocks		,0)	+ 
	isnull(PositionPNLStocksReal,0)	+ 
	isnull(CashInCopy			,0)	+ 
	isnull(AvailableCash		,0)	+			  
	isnull(PositionAmount		,0)	+ 
	isnull(PositionPNL			,0)	- 
	(isnull(TotalRealCrypto,0) + isnull(PositionPNLCryptoReal,0)) - 
	(isnull(TotalRealStocks,0) + isnull(PositionPNLStocksReal,0)) - 
	isnull(TotalNegativeLiability ,0)	+
	isnull(InProcessCashout		  ,0)    -
	isnull(actualNWA			  ,0)    +
	isnull(StockOrders            ,0)   
	AS CalculatedClosingBalance
	,ISNULL(ClosingBalance,0) as ClosingBalance
	,isnull(ClosingBalance,0) - 
	ISNULL(
		(
		isnull(TotalRealCrypto		,0)	+ 
		isnull(PositionPNLCryptoReal,0)	+ 
		isnull(TotalRealStocks		,0)	+ 
		isnull(PositionPNLStocksReal,0)	+ 
		isnull(CashInCopy			,0)	+ 
		isnull(AvailableCash		,0)	+			  
		isnull(PositionAmount		,0)	+ 
		isnull(PositionPNL			,0)	- 
		(isnull(TotalRealCrypto,0) + isnull(PositionPNLCryptoReal,0)) - 
		(isnull(TotalRealStocks,0) + isnull(PositionPNLStocksReal,0)) - 
		isnull(TotalNegativeLiability ,0)	+
		isnull(InProcessCashout		  ,0)    -
		isnull(actualNWA			  ,0)    +
		isnull(StockOrders            ,0)   
		),0)
		AS ClosingBalanceGap,
		ISNULL(
		isnull(bdcbcln.OpeningBalance				,0)		+
		isnull(bdcbcln.Deposits						,0)		+
		isnull(bdcbcln.CompensationDeposit			,0)		+
		isnull(bdcbcln.UsedBonus					,0)		+
		isnull(bdcbcln.Compensation					,0)		+
		isnull(bdcbcln.NWAAdjustment				,0)		+
		isnull(bdcbcln.CompensationPI				,0)		+
		isnull(bdcbcln.CompensationToAffiliate		,0)		+
		isnull(bdcbcln.TransferCoins				,0)		+
		isnull(bdcbcln.CompensationCashouts			,0)		+
		isnull(bdcbcln.CashoutFee					,0)		+
		isnull(bdcbcln.TransferCoinFees				,0)		+
		isnull(bdcbcln.Chargeback					,0)		+
		isnull(bdcbcln.Refund						,0)		+
		isnull(bdcbcln.OvernightFee					,0)		+
		isnull(bdcbcln.ChargebackLoss				,0)		+
		isnull(bdcbcln.OtherNegatives				,0)		+
		isnull(bdcbcln.CompensationDormantFee		,0)		+
		isnull(bdcbcln.ClientBalanceRealizedPnL		,0)		+
		isnull(bdcbcln.UnrealizedPnLChange			,0)		+
		isnull(bdcbcln.LostDebt						,0)		+
		isnull(bdcbcln.Foreclosure					,0)		+
		isnull(bdcbcln.CompensationPnLAdjustments	,0)		+
		isnull(bdcbcln.NetTransfersNWA				,0)		+
		isnull(bdcbcln.NetTransfersLiability		,0)		+
		isnull(bdcbcln.NetTransfersUnrealizedPnL	,0)		+
		isnull(bdcbcln.NegativeRefill				,0)		-
		isnull(bdcbcln.Cashouts						,0)
		,0)
		AS CycleBalance,
		ISNULL(bdcbcln.ClosingBalance,0) - 
		ISNULL(
		(
			isnull(bdcbcln.OpeningBalance				,0)		+
			isnull(bdcbcln.Deposits						,0)		+
			isnull(bdcbcln.CompensationDeposit			,0)		+
			isnull(bdcbcln.UsedBonus					,0)		+
			isnull(bdcbcln.Compensation					,0)		+
			isnull(bdcbcln.NWAAdjustment				,0)		+
			isnull(bdcbcln.CompensationPI				,0)		+
			isnull(bdcbcln.CompensationToAffiliate		,0)		+
			isnull(bdcbcln.TransferCoins				,0)		+
			isnull(bdcbcln.CompensationCashouts			,0)		+
			isnull(bdcbcln.CashoutFee					,0)		+
			isnull(bdcbcln.TransferCoinFees				,0)		+
			isnull(bdcbcln.Chargeback					,0)		+
			isnull(bdcbcln.Refund						,0)		+
			isnull(bdcbcln.OvernightFee					,0)		+
			isnull(bdcbcln.ChargebackLoss				,0)		+
			isnull(bdcbcln.OtherNegatives				,0)		+
			isnull(bdcbcln.CompensationDormantFee		,0)		+
			isnull(bdcbcln.ClientBalanceRealizedPnL		,0)		+
			isnull(bdcbcln.UnrealizedPnLChange			,0)		+
			isnull(bdcbcln.LostDebt						,0)		+
			isnull(bdcbcln.Foreclosure					,0)		+
			isnull(bdcbcln.CompensationPnLAdjustments	,0)		+
			isnull(bdcbcln.NetTransfersNWA				,0)		+
			isnull(bdcbcln.NetTransfersLiability		,0)		+
			isnull(bdcbcln.NetTransfersUnrealizedPnL	,0)		+
			isnull(bdcbcln.NegativeRefill				,0)		-
			isnull(bdcbcln.Cashouts						,0)
		),0)
		AS CycleGap
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln WITH (NOLOCK)
JOIN (SELECT DISTINCT RealCID, DateID FROM  BI_DB_dbo.BI_DB_Outliers_New  WITH (NOLOCK)) bdon
ON bdcbcln.CID = bdon.RealCID AND bdcbcln.DateID = bdon.DateID
WHERE bdcbcln.DateID = 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[Parameter 1]> AS DATE), 112) AS INT)