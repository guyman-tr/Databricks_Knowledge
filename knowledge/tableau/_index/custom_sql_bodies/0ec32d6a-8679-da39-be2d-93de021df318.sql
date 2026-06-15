SELECT a.* 
       ,b.EOD_Price AS EOD_Price_30Days
		 ,b.UsersHold AS UsersHold_30Days
		 ,b.OpenPositions AS OpenPositions_30Days
                    ,b1.EOD_Price AS EOD_Price_90Days
		 ,b1.UsersHold AS UsersHold_90Days
		 ,b1.OpenPositions AS OpenPositions_90Days
		 ,dc.MarketingRegionManualName AS NewMarketingRegion
		 ,di.Exchange
		 ,di.IndustryGroup
FROM BI_DB_dbo.BI_DB_Daily_TradeData a
JOIN DWH_dbo.Dim_Country dc
ON dc.Name = a.Country
LEFT JOIN BI_DB_dbo.BI_DB_Daily_TradeData b
ON a.Region = b.Region
AND a.Country = b.Country
AND a.InstrumentType = b.InstrumentType
AND a.InstrumentID = b.InstrumentID
AND b.Date = DATEADD(DAY,-30,a.Date)
LEFT JOIN BI_DB_dbo.BI_DB_Daily_TradeData b1
ON a.Region = b1.Region
AND a.Country = b1.Country
AND a.InstrumentType = b1.InstrumentType
AND a.InstrumentID = b1.InstrumentID
AND b1.Date = DATEADD(DAY,-90,a.Date)
LEFT JOIN [DWH_dbo].[Dim_Instrument] di WITH (NOLOCK)
ON a.InstrumentID = di.InstrumentID
WHERE a.Date >= DATEADD(MONTH,-18,GETDATE())