SELECT 
		c.from_date
		,mp.CID
		,mp.ActiveDate
		,CASE WHEN mp.ActiveDate>=from_date THEN 'After' ELSE 'Before' END Before_After_MP
		,mp.TotalDeposits
		,mp.TotalCashouts
		,mp.Revenue_Total
		,mp.NewTrades_Total
		,mp.NewTrades_Real_Crypto
		,mp.NewTrades_CFD_Crypto
		,mp.AmountIn_NewTrades_Real_Crypto
		,mp.AmountIn_NewTrades_CFD_Crypto
		,mp.AmountIn_NewTrades_Total
		,mp.ClusterDetail

FROM #CID c
 JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
ON mp.CID = c.CID
AND mp.ActiveDate>=DATEADD(mm,-6,from_date)
AND mp.ActiveDate<=DATEADD(mm,6,from_date)