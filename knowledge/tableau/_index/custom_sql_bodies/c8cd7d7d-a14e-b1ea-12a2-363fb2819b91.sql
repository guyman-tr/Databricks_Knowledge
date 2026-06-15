SELECT	        di.InstrumentType AS 'Asset_Class'
                ,CASE   WHEN di.InstrumentTypeID= 5 AND dp.MirrorID = 0 THEN di.InstrumentDisplayName END AS 'Stock_Name'
		,CASE	WHEN dp.MirrorID = 0 THEN 'Manual'
				WHEN dp.MirrorID > 0 THEN 'Copy'
				ELSE 'Error' END AS 'Execution_Method'
		,COUNT(dp.PositionID) AS 'Trade_Count'
		,SUM(ISNULL(dp.NetProfit,0)) AS 'Realised_PL'
		,SUM(ISNULL((dp.InitialAmountCents/100),0)*ISNULL(dp.Leverage,1)) 'Notional'
		,SUM(ISNULL((dp.InitialAmountCents/100),0)) AS 'Invested_Amount'
		,COUNT(CASE WHEN ISNULL(dp.NetProfit,0)>0 THEN dp.PositionID END) AS 'Win_Trades_Count' 
		,COUNT(CASE WHEN ISNULL(dp.NetProfit,0)<=0 THEN dp.PositionID END) AS 'Lose_Trades_Count' 
		,SUM(CASE WHEN ISNULL(dp.NetProfit,0)>0 THEN ISNULL(dp.NetProfit,0) ELSE 0 END) AS 'Win_Trades_Amount' 
		,SUM(CASE WHEN ISNULL(dp.NetProfit,0)<=0 THEN ISNULL(dp.NetProfit,0) ELSE 0 END) AS 'Lose_Trades_Amount' 
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Dim_Instrument di
ON dp.InstrumentID = di.InstrumentID
WHERE	dp.CID = <[Parameters].[Parameter 1]>
		AND dp.OpenDateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
                AND dp.OpenDateID <= CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)  
                AND ISNULL(dp.IsPartialCloseChild,0) = 0

GROUP BY di.InstrumentType,
	CASE WHEN di.InstrumentTypeID= 5 AND dp.MirrorID = 0 THEN di.InstrumentDisplayName END
	,CASE	WHEN dp.MirrorID = 0 THEN 'Manual'
				WHEN dp.MirrorID > 0 THEN 'Copy'
				ELSE 'Error' END