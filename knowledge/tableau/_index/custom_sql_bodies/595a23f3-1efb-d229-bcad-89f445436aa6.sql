SELECT
	pan.[Region]
   ,pan.Country
   ,pan.Active_Month AS RevenueMonth
   ,(CASE
		WHEN pan.Revenue_Total > 1000 THEN '1. >$1000 Revenue'
		WHEN pan.Revenue_Total > 500 THEN '2. $501-$1000 Revenue'
		WHEN pan.Revenue_Total > 100 THEN '3. $101-$500 Revenue'
		WHEN pan.Revenue_Total > 50 THEN '4. $51-$101 Revenue'
		WHEN pan.Revenue_Total > 10 THEN '5. $11-$50 Revenue'
		WHEN pan.Revenue_Total <= 10 THEN '6. $0-$10 Revenue'
		ELSE 'NULL'
	END)
	AS RevenueCategory
	--,(CASE WHEN pan.EOM_Club IN ('HighBronze', 'LowBronze') THEN 'Bronze' ELSE pan.EOM_Club END) AS Club
   ,dcl.ClusterDetail
   ,COUNT(DISTINCT pan.CID) AS NumberOfClients
   ,SUM([Revenue_Total]) AS [Revenue_Total]
	--,SUM([Revenue_Total]) / COUNT(DISTINCT pan.CID) AS AverageRevenuePerClient
   ,SUM(pan.EOM_Equity) AS EOM_Equity


FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] pan WITH (NOLOCK)
LEFT JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
	ON fd.CID = pan.CID
LEFT JOIN [BI_DB].[dbo].[BI_DB_CID_DailyCluster] dcl WITH (NOLOCK)
	ON pan.CID = dcl.CID
		AND dcl.IsLastCluster = 1
WHERE pan.ActiveDate >= '20210701'
AND pan.ActiveDate >= DATEADD(MONTH, -4, GETDATE())

GROUP BY pan.[Region]
		,pan.Country--, (CASE WHEN pan.EOM_Club IN ('HighBronze', 'LowBronze') THEN 'Bronze' ELSE pan.EOM_Club END)
		,pan.Active_Month
		,(CASE
			 WHEN pan.Revenue_Total > 1000 THEN '1. >$1000 Revenue'
			 WHEN pan.Revenue_Total > 500 THEN '2. $501-$1000 Revenue'
			 WHEN pan.Revenue_Total > 100 THEN '3. $101-$500 Revenue'
			 WHEN pan.Revenue_Total > 50 THEN '4. $51-$101 Revenue'
			 WHEN pan.Revenue_Total > 10 THEN '5. $11-$50 Revenue'
			 WHEN pan.Revenue_Total <= 10 THEN '6. $0-$10 Revenue'
			 ELSE 'NULL'
		 END)
		,dcl.ClusterDetail