SELECT
	di.InstrumentID
  , di.Name
  , fcpws.OccurredDate
  , fcpws.AskSpreaded
  , fcpws.BidSpreaded
  , fcpws.Ask
  , fcpws.Bid
  , CONVERT (VARCHAR(6), fcpws.OccurredDate, 112) AS YearMonth
FROM DWH_dbo.Fact_CurrencyPriceWithSplit fcpws
JOIN DWH_dbo.Dim_Instrument di
	ON fcpws.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Date dd
	ON dd.DateKey = fcpws.OccurredDateID
WHERE dd.IsLastDayOfMonth = 'Y'
AND di.InstrumentTypeID = 10
AND fcpws.OccurredDate =EOMONTH(GETDATE(), -1)