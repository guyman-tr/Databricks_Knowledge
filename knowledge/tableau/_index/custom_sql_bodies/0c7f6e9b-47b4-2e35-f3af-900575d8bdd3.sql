SELECT YearMonth,
EOMONTH (Date) AS 'Date',	 
Regulation,
COUNT(DISTINCT DateID) Num_of_days,
sum(ISNULL(bdcbcln.CashInCopy,0))+sum(ISNULL(bdcbcln.AvailableCash,0)) AS 'Total Cash',
sum(ISNULL(bdcbcln.PositionAmount,0))+sum(ISNULL(bdcbcln.PositionPNL,0))-sum(ISNULL(bdcbcln.TotalRealCrypto,0))-SUM(ISNULL(bdcbcln.PositionPNLCryptoReal,0))-sum(ISNULL(bdcbcln.TotalRealStocks,0))-SUM(ISNULL(bdcbcln.PositionPNLStocksReal,0)) AS 'Equity CFD',
CAST(GETDATE() AS DATE) AS LoadDate
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
WHERE bdcbcln.DateID >= 20220101
AND DateID<=CAST(FORMAT( GETDATE()-1, 'yyyyMMdd') AS INT)
AND bdcbcln.IsCreditReportValidCB=1
GROUP BY 
YearMonth,
EOMONTH (Date),
Regulation