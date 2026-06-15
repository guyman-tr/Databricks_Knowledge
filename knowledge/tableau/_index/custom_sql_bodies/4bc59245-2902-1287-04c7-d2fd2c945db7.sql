SELECT EOMONTH(bdcbcln.Date) 'Month',
dc.MarketingRegionManualName ,
bdcbcln.Country,
sum(ISNULL(bdcbcln.CashInCopy,0))+sum(ISNULL(bdcbcln.AvailableCash,0)) AS 'Total Cash',
sum(ISNULL(bdcbcln.PositionAmount,0))+sum(ISNULL(bdcbcln.PositionPNL,0))-sum(ISNULL(bdcbcln.TotalRealCrypto,0))-SUM(ISNULL(bdcbcln.PositionPNLCryptoReal,0))-sum(ISNULL(bdcbcln.TotalRealStocks,0))-SUM(ISNULL(bdcbcln.PositionPNLStocksReal,0)) AS 'Equity CFD'


FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln

LEFT JOIN DWH_dbo.Dim_Country dc ON bdcbcln.Country=dc.Name
WHERE bdcbcln.DateID BETWEEN 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) 
AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND bdcbcln.IsCreditReportValidCB=1

GROUP BY 
--bdcbcln.Regulation
EOMONTH(bdcbcln.Date),
dc.MarketingRegionManualName,
bdcbcln.Country