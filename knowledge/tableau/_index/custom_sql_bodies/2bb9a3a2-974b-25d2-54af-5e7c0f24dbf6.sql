SELECT oc.Date, 
SUM(oc.PositionAmount) TotalAmountOpenClose, 
SUM(oc.IBHedgedAmount) IBHedgedAmount ,
sum(oc.PositionAmount_GBP) AS TotalAmountOpenClose_GBP,
SUM(oc.IBHedgedAmount_GBP) IBHedgedAmount_GBP
FROM
(
SELECT CAST(dp.OpenOccurred AS Date) Date, 
SUM(dp.Amount) PositionAmount
,SUM(CASE WHEN di.ISINCountryCode IN
('AT','BE',
'CH','DE',
'DK','ES',
'FI','FR',
'FRA','GB',
'GER','GI',
'IE','IL',
'IM','IT',
'JE','LU',
'NL','NO',
'PT','SE') THEN dp.Amount END) AS IBHedgedAmount
,SUM(dp.Amount/cpsp.Ask) AS PositionAmount_GBP 
,SUM(CASE WHEN di.ISINCountryCode IN
('AT','BE',
'CH','DE',
'DK','ES',
'FI','FR',
'FRA','GB',
'GER','GI',
'IE','IL',
'IM','IT',
'JE','LU',
'NL','NO',
'PT','SE') THEN dp.Amount/cpsp.Ask END) AS IBHedgedAmount_GBP
FROM DWH_dbo.[Dim_Position] dp
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fsc.RealCID=dp.CID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND dp.CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.[Dim_Country] dc ON dc.CountryID = fsc.CountryID
JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK) ON cpsp.OccurredDateID=dp.OpenDateID
JOIN DWH_dbo.Dim_Instrument di1 ON cpsp.InstrumentID = di1.InstrumentID AND di1.InstrumentID=2
WHERE fsc.IsValidCustomer = 1 
AND dp.RegulationIDOnOpen = 2
AND di.InstrumentType IN ('Stocks', 'ETF') AND ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1
AND dp.OpenDateID  BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
 AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)

GROUP BY CAST(dp.OpenOccurred AS Date)

UNION ALL

SELECT CAST(dp.CloseOccurred AS Date) Date,
SUM(dp.Amount) PositionAmount--, SUM(dp.Amount * dp.Leverage) NotionalAmount
,SUM(CASE WHEN di.ISINCountryCode IN
('AT','BE',
'CH','DE',
'DK','ES',
'FI','FR',
'FRA','GB',
'GER','GI',
'IE','IL',
'IM','IT',
'JE','LU',
'NL','NO',
'PT','SE') THEN dp.Amount END) AS IBHedgedAmount,
SUM(dp.Amount/cpsp.Ask)PositionAmount_GBP,
SUM(CASE WHEN di.ISINCountryCode IN
('AT','BE',
'CH','DE',
'DK','ES',
'FI','FR',
'FRA','GB',
'GER','GI',
'IE','IL',
'IM','IT',
'JE','LU',
'NL','NO',
'PT','SE') THEN dp.Amount/cpsp.Ask END)IBHedgedAmount_GBP

FROM DWH_dbo.[Dim_Position] dp
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fsc.RealCID=dp.CID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND dp.CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.[Dim_Country] dc ON dc.CountryID = fsc.CountryID
JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK) ON cpsp.OccurredDateID=dp.CloseDateID
JOIN DWH_dbo.Dim_Instrument di1 ON cpsp.InstrumentID = di1.InstrumentID AND di1.InstrumentID=2
WHERE fsc.IsValidCustomer = 1 
AND dp.RegulationIDOnOpen = 2
AND di.InstrumentType IN ('Stocks', 'ETF') AND ISNULL(dp.IsSettledOnOpen, dp.IsSettled) = 1
AND dp.CloseDateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
 AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)

GROUP BY CAST(dp.CloseOccurred AS Date)

) oc
GROUP BY oc.Date