SELECT dcc.Date ReportDate,
dcc.InstrumentID,
a.OccurredDate Historical_Date ,
SUM(bddztsn.NOP)NOP,
avg(BidSpreaded) Bid, 
avg(AskSpreaded) Ask,
avg(Mid_Rate) Mid 
FROM
(SELECT DISTINCT Date, InstrumentID FROM BI_DB_DailyCommoditiesReport_Clients ) dcc
left join BI_DB_DailyZero_TreeSize_NEW bddztsn
on  bddztsn.Date>=Dateadd(Day,-31,dcc.Date) AND bddztsn.Date<dcc.Date AND bddztsn.InstrumentID=dcc.InstrumentID
left join 
(SELECT fcpws.OccurredDate,
fcpws.InstrumentID,
fcpws.BidSpreaded,
fcpws.AskSpreaded,
(fcpws.BidSpreaded+fcpws.AskSpreaded)/2 Mid_Rate
FROM DWH.dbo.Fact_CurrencyPriceWithSplit fcpws
WHERE InstrumentID IN (17,18,22) 
)a
on a.OccurredDate=bddztsn.Date   AND bddztsn.InstrumentID=a.InstrumentID 
GROUP BY dcc.Date ,
dcc.InstrumentID,
a.OccurredDate