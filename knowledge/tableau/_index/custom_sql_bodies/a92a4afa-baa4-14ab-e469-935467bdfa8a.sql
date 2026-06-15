SELECT oc.Date, 
SUM(oc.PositionAmount) TotalAmountOpenClose ,
sum(oc.PositionAmount_GBP) AS 'TotalAmountOpenClose (GBP)'
FROM
(
SELECT CAST(dp.OpenOccurred AS Date) Date, 
SUM(dp.Amount* dp.Leverage) PositionAmount,--, SUM(dp.Amount * dp.Leverage) NotionalAmount
SUM(dp.Amount* dp.Leverage/cpsp.Ask) AS PositionAmount_GBP
FROM DWH_dbo.[Dim_Position] dp
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
--JOIN DWH_dbo.[Dim_Customer] c ON c.RealCID = dp.CID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON dp.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND dp.OpenDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.[Dim_Country] dc ON dc.CountryID = fsc.CountryID
JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK) ON cpsp.OccurredDateID=dp.OpenDateID
JOIN DWH_dbo.Dim_Instrument di1 ON cpsp.InstrumentID = di1.InstrumentID AND di1.InstrumentID=2
WHERE fsc.IsValidCustomer = 1 
AND dp.RegulationIDOnOpen = 2
AND ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0
AND dp.OpenDateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
GROUP BY CAST(dp.OpenOccurred AS Date)

UNION ALL

SELECT CAST(dp.CloseOccurred AS Date) Date, 
SUM(dp.Amount* dp.Leverage) PositionAmount,--, SUM(dp.Amount * dp.Leverage) NotionalAmount
SUM(dp.Amount* dp.Leverage/cpsp.Ask) AS PositionAmount_GBP
FROM DWH_dbo.[Dim_Position] dp
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON dp.CID=fsc.RealCID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND dp.CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.[Dim_Country] dc ON dc.CountryID = fsc.CountryID
JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK) ON cpsp.OccurredDateID=dp.CloseDateID
JOIN DWH_dbo.Dim_Instrument di1 ON cpsp.InstrumentID = di1.InstrumentID AND di1.InstrumentID=2
WHERE fsc.IsValidCustomer = 1 
AND dp.RegulationIDOnOpen = 2
AND ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 0
AND dp.CloseDateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
GROUP BY CAST(dp.CloseOccurred AS Date)

) oc
GROUP BY oc.Date