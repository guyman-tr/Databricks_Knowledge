SELECT * 
	, CASE  WHEN a.TotalTradingRevenue < 1 THEN 1
			WHEN a.TotalTradingRevenue < 10 then 10
			WHEN a.TotalTradingRevenue < 100 then 100
			WHEN a.TotalTradingRevenue < 500 then 500
			WHEN a.TotalTradingRevenue < 1000 then 1000
			WHEN a.TotalTradingRevenue < 2000 then 2000
			WHEN a.TotalTradingRevenue < 5000 then 5000
			WHEN a.TotalTradingRevenue < 10000 then 10000
			WHEN a.TotalTradingRevenue < 20000 then 20000
			WHEN a.TotalTradingRevenue >= 20000 then 20001
		ELSE 0 
		END AS [GROUP]
	, 'ThisMonth' AS GroupPeriod
FROM 
(
SELECT
	bddcrtm.RealCID
  , sum(isnull(bddcrtm.FullCommissions		,0)) + 
	 sum(isnull(bddcrtm.RollOverFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFeeByPercent	,0)) + 
	 sum(isnull(bddcrtm.AdminFee			,0)) + 
	 sum(isnull(bddcrtm.SpotAdjustFee		,0)) 
	AS TotalTradingRevenue
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth bddcrtm
WHERE IsValidCustomer = 1
AND NOT(
		ISNULL(bddcrtm.FullCommissions,0) = 0 
		AND ISNULL(bddcrtm.RollOverFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFeeByPercent,0) = 0 
		AND ISNULL(bddcrtm.AdminFee,0) = 0 
		AND ISNULL(bddcrtm.SpotAdjustFee,0) = 0 
		)
GROUP BY bddcrtm.RealCID
) a

UNION ALL 

SELECT * 
	, CASE WHEN a.TotalTradingRevenue < 1 THEN 1
			WHEN a.TotalTradingRevenue < 10 then 10
			WHEN a.TotalTradingRevenue < 100 then 100
			WHEN a.TotalTradingRevenue < 200 then 200
			WHEN a.TotalTradingRevenue < 300 then 300
			WHEN a.TotalTradingRevenue < 400 then 400
			WHEN a.TotalTradingRevenue < 500 then 500
			WHEN a.TotalTradingRevenue < 1000 then 1000
			WHEN a.TotalTradingRevenue < 5000 then 5000
			WHEN a.TotalTradingRevenue >= 5000 then 5001
		ELSE 0 
		END AS [GROUP]
	, 'Yesterday' AS GroupPeriod
FROM 
(
SELECT
	bddcrtm.RealCID
  , sum(isnull(bddcrtm.FullCommissions		,0)) + 
	 sum(isnull(bddcrtm.RollOverFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFeeByPercent	,0)) + 
	 sum(isnull(bddcrtm.AdminFee			,0)) + 
	 sum(isnull(bddcrtm.SpotAdjustFee		,0)) 
	AS TotalTradingRevenue
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday bddcrtm
WHERE IsValidCustomer = 1
AND NOT(
		ISNULL(bddcrtm.FullCommissions,0) = 0 
		AND ISNULL(bddcrtm.RollOverFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFeeByPercent,0) = 0 
		AND ISNULL(bddcrtm.AdminFee,0) = 0 
		AND ISNULL(bddcrtm.SpotAdjustFee,0) = 0 
		)
GROUP BY bddcrtm.RealCID
) a

UNION ALL 

SELECT * 
	, CASE WHEN a.TotalTradingRevenue < 1 THEN 1
			WHEN a.TotalTradingRevenue < 10 then 10
			WHEN a.TotalTradingRevenue < 100 then 100
			WHEN a.TotalTradingRevenue < 500 then 500
			WHEN a.TotalTradingRevenue < 1000 then 1000
			WHEN a.TotalTradingRevenue < 5000 then 5000
			WHEN a.TotalTradingRevenue < 10000 then 10000
			WHEN a.TotalTradingRevenue < 50000 then 50000
			WHEN a.TotalTradingRevenue < 100000 then 100000
			WHEN a.TotalTradingRevenue >= 100000 then 100001
		ELSE 0 
		END AS [GROUP]
	, 'ThisYear' AS GroupPeriod
FROM 
(
SELECT
	bddcrtm.RealCID
  , sum(isnull(bddcrtm.FullCommissions		,0)) + 
	 sum(isnull(bddcrtm.RollOverFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFee			,0)) + 
	 sum(isnull(bddcrtm.TicketFeeByPercent	,0)) + 
	 sum(isnull(bddcrtm.AdminFee			,0)) + 
	 sum(isnull(bddcrtm.SpotAdjustFee		,0)) 
	AS TotalTradingRevenue
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear bddcrtm
WHERE IsValidCustomer = 1
AND NOT(
		ISNULL(bddcrtm.FullCommissions,0) = 0 
		AND ISNULL(bddcrtm.RollOverFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFee,0) = 0 
		AND ISNULL(bddcrtm.TicketFeeByPercent,0) = 0 
		AND ISNULL(bddcrtm.AdminFee,0) = 0 
		AND ISNULL(bddcrtm.SpotAdjustFee,0) = 0 
		)
GROUP BY bddcrtm.RealCID
) a