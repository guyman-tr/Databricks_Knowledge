SELECT d.TimeRange
	  ,d.MarketingRegion
	  ,FirstOfMonth
	  ,d.KPI
	  ,d.Achievement
	  ,k.target
FROM #DDR d
JOIN #KPIs k
ON d.TimeRange = k.TimeRange
AND d.KPI = k.kpi
AND d.MarketingRegion=k.region
AND d.FirstOfMonth=k.Date

UNION 

	SELECT d.TimeRange
	  ,'Total' AS MarketingRegion
	  ,FirstOfMonth
	  ,d.KPI
	  ,SUM(d.Achievement) Achievement
	  ,SUM(CAST( k.target AS BIGINT)) target
FROM #DDR d
JOIN #KPIs k
ON d.TimeRange = k.TimeRange
AND d.KPI = k.kpi
AND d.MarketingRegion=k.region
AND d.FirstOfMonth=k.Date
GROUP BY d.TimeRange
	  ,FirstOfMonth
	  ,d.KPI