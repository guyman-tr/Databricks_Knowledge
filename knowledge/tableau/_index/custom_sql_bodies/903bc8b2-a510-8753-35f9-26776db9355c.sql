SELECT * 

FROM (
SELECT p.InstrumentID,p.InstrumentDisplayName, 
avg(p.BidSpreaded) AS Avg_Price,
STDEVP(p.BidSpreaded)/avg(p.BidSpreaded) AS Volatility_ver1,
STDEVP((p.BidSpreaded/yestr_pr)-1) AS volatility_price_Change,
STDEVP((p.BidSpreaded/yestr_pr)-1) SD_price_Change,
AVG((p.BidSpreaded/yestr_pr)-1) AVG_price_Change,
STDEVP(p.BidSpreaded) SD_price,
COUNT(*) Days_Appread
			FROM	(
			SELECT  cast(ISNULL(LAG(fcpws.BidSpreaded)OVER(PARTITION BY di.InstrumentID ORDER BY fcpws.OccurredDate ASC),fcpws.BidSpreaded) AS FLOAT) AS yestr_pr,fcpws.*,di.InstrumentDisplayName
			FROM DWH_dbo.Fact_CurrencyPriceWithSplit fcpws
			JOIN DWH_dbo.Dim_Instrument di ON fcpws.InstrumentID = di.InstrumentID 
			WHERE fcpws.OccurredDateID >= 20230101 
			AND di.InstrumentTypeID =1 
			AND len(di.InstrumentDisplayName) > 0  
			aND di.InstrumentDisplayName NOT LIKE 'ETORIAN%'
			AND fcpws.isvalid =1 
			
			) p
GROUP BY  p.InstrumentDisplayName,p.InstrumentID
HAVING COUNT(*)>1
) a