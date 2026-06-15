SELECT die.Date
			 ,die.InstrumentID
			 ,die.InstrumentDisplayName
			 ,die.ISINCode
			 ,CASE WHEN die.IsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS [Buy/Sell]
			 ,die.CurrencyPrimary
			 ,die.IB_Units
			 ,die.eToro_Units
			 ,fcpws.Ask
			 ,fcpws.Bid
			 ,fcpws.ConvertRateIsBuy_1
			 ,fcpws.ConvertRateIsBuy_0
			 ,CASE WHEN die.IsBuy = 1 THEN die.IB_Units*fcpws.Bid*fcpws.ConvertRateIsBuy_1 
									   ELSE die.IB_Units*fcpws.Ask*fcpws.ConvertRateIsBuy_0
									   END AS IB_AmountUSD
			,CASE WHEN die.IsBuy = 1 THEN die.eToro_Units*fcpws.Bid*fcpws.ConvertRateIsBuy_1 
									   ELSE die.eToro_Units*fcpws.Ask*fcpws.ConvertRateIsBuy_0
									   END AS eToro_AmountUSD
			 ,die.UpdateDate
			 ,die.HedgeServerID
                         ,die.LastExecutionTime
FROM Dealing_dbo.Dealing_IBRecon_EODHoldings die
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit fcpws
ON die.InstrumentID = fcpws.InstrumentID AND die.Date = fcpws.OccurredDate 
WHERE die.HedgeServerID = 126 OR die.ClientAccountID= 'UL3148833'