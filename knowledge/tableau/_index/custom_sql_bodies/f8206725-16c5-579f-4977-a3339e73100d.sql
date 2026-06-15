SELECT CID
  , bdcbcln.Regulation
  , bdcbcln.IsCreditReportValidCB
  , CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AS DateID
  ,	isnull(bdcbcln.ClosingBalance,0) ClosingBalance
  , isnull(bdcbcln.RealCryptoClosingBalance,0) RealCryptoClosingBalance
  , isnull(bdcbcln.RealStocksClosingBalance,0) RealStocksClosingBalance
  , ISNULL(bdcbcln.RealFuturesClosingBalance,0) RealFuturesClosingBalance
  , ISNULL(bdcbcln.ClosingBalance,0) 
	-  ISNULL(bdcbcln.RealCryptoClosingBalance,0) 
	-  ISNULL(bdcbcln.RealStocksClosingBalance,0) 
	-  ISNULL(bdcbcln.RealFuturesClosingBalance,0) 
	+  ISNULL(bdcbcln.actualNWA,0) AS NegativeBalanceCheck
  , ISNULL(bdcbcln.AvailableCash,0) AS AvailableCash
, ISNULL(bdcbcln.actualNWA,0) AS actualNWA 
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
WHERE bdcbcln.DateID =  CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
AND bdcbcln.TransferDirection = 1
AND  ISNULL(bdcbcln.ClosingBalance,0) 
	-  ISNULL(bdcbcln.RealCryptoClosingBalance,0) 
	-  ISNULL(bdcbcln.RealStocksClosingBalance,0) 
	-  ISNULL(bdcbcln.RealFuturesClosingBalance,0) 
	+  ISNULL(bdcbcln.actualNWA,0)  < 0
AND bdcbcln.IsCreditReportValidCB = 1