SELECT 
	  bdcbcln.CID,
	  bdcbcln.Date,
	  bdcbcln.Regulation,
	  bdcbcln.Club,
	  bdcbcln.MifidCategory,
	  ISNULL(bdcbcln.ClosingBalance,0) AS [Closing Balance USD($)],
	  ISNULL(bdcbcln.RealCryptoClosingBalance,0) AS [RealCrypto Closing Balance USD($)],
	  ISNULL(bdcbcln.RealStocksClosingBalance,0) AS [RealStocks Closing Balance USD($)],
	  (ISNULL(bdcbcln.ClosingBalance,0) - ISNULL(bdcbcln.RealCryptoClosingBalance,0))/ Rate AS [ClosingBalanceAdj_EUR],
	  (ISNULL(bdcbcln.RealStocksClosingBalance,0))/ Rate  AS [RealStocksBalance_EUR]
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
JOIN (SELECT 
	  	 [Date]
	  	,ECBRate AS Rate
	  FROM
	  	 (SELECT
	  	 EOMONTH(a.Date) AS [Date],
	  	 ECBRate,
	  	 ROW_NUMBER() OVER (PARTITION BY EOMONTH(Date) ORDER BY Date DESC) AS Rn
	  	 FROM BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI a
	  	 WHERE DateID>=20200101) tab
	  WHERE Rn=1) tab ON tab.Date=bdcbcln.Date

WHERE bdcbcln.DateID IN (SELECT dd.DateKey FROM DWH_dbo.Dim_Date dd WHERE dd.IsLastDayOfMonth='Y' and dd.DateKey>=20200101)
	  AND bdcbcln.TransferDirection=1 
	  AND bdcbcln.ClosingBalance IS NOT NULL
	  AND bdcbcln.ClosingBalance-RealCryptoClosingBalance>=20000