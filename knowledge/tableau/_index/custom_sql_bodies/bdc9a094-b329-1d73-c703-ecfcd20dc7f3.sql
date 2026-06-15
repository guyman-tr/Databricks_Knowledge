-- ClubFunded
SELECT MarketingRegion, ActiveDate, 'ClubFunded' AS Metric, 'Actual' AS Type, ClubFunded AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'ClubFunded' AS Metric, 'Target' AS Type, ClubFunded_Target AS Value
FROM #final f

-- Revenue
UNION
SELECT MarketingRegion, ActiveDate, 'Revenue' AS Metric, 'Actual' AS Type, Revenue AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'Revenue' AS Metric, 'Target' AS Type, Revenue_Target AS Value
FROM #final f

-- FTD
UNION
SELECT MarketingRegion, ActiveDate, 'FTD' AS Metric, 'Actual' AS Type, FTD AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'FTD' AS Metric, 'Target' AS Type, FTD_Target AS Value
FROM #final f

-- Deposits
UNION
SELECT MarketingRegion, ActiveDate, 'Deposits' AS Metric, 'Actual' AS Type, Deposits AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'Deposits' AS Metric, 'Target' AS Type, Deposits_Target AS Value
FROM #final f

-- Cashouts
UNION
SELECT MarketingRegion, ActiveDate, 'Cashouts' AS Metric, 'Actual' AS Type, Cashouts AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'Cashouts' AS Metric, 'Target' AS Type, Cashouts_Target AS Value
FROM #final f

-- Net Deposits
UNION
SELECT MarketingRegion, ActiveDate, 'NetDeposits' AS Metric, 'Actual' AS Type, NetDeposits AS Value
FROM #final f
UNION
SELECT MarketingRegion, ActiveDate, 'NetDeposits' AS Metric, 'Target' AS Type, NetDeposits_Target AS Value
FROM #final f

-- AUA (only Target column provided)
UNION
SELECT MarketingRegion, ActiveDate, 'AUA' AS Metric, 'Target' AS Type, AUA_Target AS Value
FROM #final f

--ORDER BY MarketingRegion, ActiveDate, Metric, Type;