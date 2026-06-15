SELECT di.Name AS Instrument
, di.InstrumentDisplayName
,SUM(CASE WHEN [OccurredDate] =dateadd(day,-1, cast(getdate() as date)) THEN [Ask] END)
/ 
SUM(CASE WHEN [OccurredDate] = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) THEN [Ask] END) - 1
AS MTD_Change

,SUM(CASE WHEN [OccurredDate] =dateadd(day,-1, cast(getdate() as date)) THEN [Ask] END)
/ 
SUM(CASE WHEN [OccurredDate] = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) THEN [Ask] END) - 1
AS YTD_Change

,SUM(CASE WHEN [OccurredDate] =dateadd(day,-1, cast(getdate() as date)) THEN [Ask] END)
/ 
SUM(CASE WHEN CAST([OccurredDate] AS Date) = CAST(e.EarliestDate AS Date) THEN [Ask] END) - 1
AS Change_Since_Launch
,e.EarliestDate
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK)
JOIN [DWH_dbo].[Dim_Date] dd WITH (NOLOCK) ON cpsp.OccurredDateID = dd.DateKey
JOIN [DWH_dbo].[Dim_Instrument] di ON di.InstrumentID = cpsp.InstrumentID
JOIN
(SELECT di.Name Instrument, MIN(cpsp.OccurredDate) EarliestDate
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Date] dd WITH (NOLOCK) ON cpsp.OccurredDateID = dd.DateKey
JOIN [DWH_dbo].[Dim_Instrument] di ON di.InstrumentID = cpsp.InstrumentID
GROUP BY di.Name)
e
ON e.Instrument = di.Name
WHERE [OccurredDate] =dateadd(day,-1, cast(getdate() as date))
OR [OccurredDate] = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)
OR [OccurredDate] = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0)
OR [OccurredDate] = e.EarliestDate
GROUP BY di.Name, di.InstrumentDisplayName,e.EarliestDate