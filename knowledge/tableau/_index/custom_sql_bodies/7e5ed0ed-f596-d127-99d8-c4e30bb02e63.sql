SELECT * 
FROM #mp m
	LEFT JOIN #kpis k ON m.ActiveDate = k.[Month] AND m.MarketingRegion = k.Region
--ORDER BY
--	m.MarketingRegion, m.ActiveDate