SELECT pan.[CID]
, dc.FirstName + ' ' + dc.LastName AS ClientName
, [fd].[Manager]
, [fd].[Club]
, [fd].[RealizedEquity]
, (CASE WHEN [fd].[RealizedEquity] < 5000 THEN 5000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 10000 THEN 10000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 25000 THEN 25000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 50000 THEN 50000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 250000 THEN 250000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] >= 250000 THEN NULL
END) AS AmountBelowUpgradeThreshold
, (CASE WHEN [fd].[RealizedEquity] < 5000 THEN [fd].[RealizedEquity] / 5000.0
WHEN [fd].[RealizedEquity] < 10000 THEN [fd].[RealizedEquity] / 10000.0
WHEN [fd].[RealizedEquity] < 25000 THEN [fd].[RealizedEquity] / 25000.0
WHEN [fd].[RealizedEquity] < 50000 THEN [fd].[RealizedEquity] / 50000.0
WHEN [fd].[RealizedEquity] < 250000 THEN [fd].[RealizedEquity] / 250000.0
WHEN [fd].[RealizedEquity] >= 250000 THEN NULL
END) AS PercentageOfUpgradeThreshold
, fd.[LastContactDate]
, DATEDIFF(HOUR, fd.[LastContactDate], GETDATE()) / 24.0 AS DaysSinceLastContact
, SUM(CASE WHEN [pan].[ActiveDate] >= DATEADD(month, DATEDIFF(month, 0, GETDATE()) -3, 0) THEN pan.Revenue_Total END) AS RevenueLast3FullMonths
, SUM(CASE WHEN [pan].[ActiveDate] = DATEADD(month, DATEDIFF(month, 0, GETDATE()) -1, 0) THEN pan.Revenue_Total END) AS RevenueLastMonth
, SUM(CASE WHEN [pan].[ActiveDate] = DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) THEN pan.Revenue_Total END) AS RevenueThisMonth
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] pan WITH (NOLOCK)
JOIN [DWH_dbo].Dim_Customer dc WITH (NOLOCK) ON pan.CID = dc.RealCID
JOIN [DWH_dbo].[Dim_Country] dc1 ON dc1.CountryID = dc.CountryID
LEFT JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON fd.CID = dc.[RealCID]
WHERE [pan].[ActiveDate] >= DATEADD(month, DATEDIFF(month, 0, GETDATE()) -3, 0)
AND dc1.[Region] = 'UK' AND [dc].[IsValidCustomer] = 1 AND [fd].[Club] IN ('Gold', 'Platinum', 'Platinum Plus', 'Diamond') --AND [pan].[CID] = 3711653
GROUP BY pan.[CID]
, dc.FirstName + ' ' + dc.LastName
, [fd].[Manager]
, [fd].[Club]
, [fd].[RealizedEquity]
, (CASE WHEN [fd].[RealizedEquity] < 5000 THEN 5000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 10000 THEN 10000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 25000 THEN 25000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 50000 THEN 50000 - [fd].[RealizedEquity]
WHEN [fd].[RealizedEquity] < 250000 THEN 250000 - [fd].[RealizedEquity]
END)
, fd.[LastContactDate]
, DATEDIFF(HOUR, fd.[LastContactDate], GETDATE()) / 24.0