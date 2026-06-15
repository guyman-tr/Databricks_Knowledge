SELECT          
         mp.ActiveDate
		,cf.Gender
		--,CASE WHEN mp.EOM_Club LIKE '%Bronze%' THEN 'Bronze' ELSE mp.EOM_Club END EOM_Club
		,SUM(mp.NewTrades_Total) NewTrades_Total
		,SUM(mp.AmountIn_NewTrades_Total) AmountIn_NewTrades_Total
		,SUM(mp.ACC_PnL_Total) ACC_PnL_Total
		,SUM(mp.PnL_Total) PnL_Total
		,SUM(mp.ACC_Revenue_Total) ACC_Revenue_Total
		,SUM(mp.Revenue_Total) Revenue_Total
                ,SUM(mp.Active) Active
		,SUM(mp.ActiveOpen) ActiveOpen
		,SUM(mp.IsFunded_New) IsFunded_New
                ,SUM(mp.EOM_Equity) EOM_Equity
                ,SUM(CASE WHEN mp.Revenue_Total>0 THEN 1 ELSE 0 END) PositiveRevenue
		,SUM(CASE WHEN mp.PnL_Total>0 THEN 1 ELSE 0 END) PositivePnL	



FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp WITH (NOLOCK)
JOIN DWH.dbo.Dim_Customer cf WITH (NOLOCK)
ON mp.CID = cf.RealCID
WHERE mp.ActiveDate>=CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -6,GETDATE())), 0) AS DATE)--DATEADD(MONTH,-6,GETDATE())
AND cf.Gender IS NOT NULL
GROUP BY mp.ActiveDate, cf.Gender