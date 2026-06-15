SELECT dp.ActiveDate
, dp.Country
, dp.EOD_Regulation
, COUNT(DISTINCT dp.CID) AS ClientCount
, SUM(Equity) AS [Unrealised Equity]
FROM [BI_DB_dbo].BI_DB_CID_DailyPanel_FullData dp
JOIN [DWH_dbo].Dim_Customer dc
	ON dc.RealCID = dp.CID
WHERE dp.EOD_Regulation = 'FCA'
 AND dp.DateID between  CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND dc.IsValidCustomer = 1
AND dp.Equity > 0
GROUP BY dp.ActiveDate
, dp.Country 
, dp.EOD_Regulation