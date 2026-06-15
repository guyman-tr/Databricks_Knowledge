SELECT di.Name AS Instrument, di.InstrumentDisplayName
, [OccurredDate] Date
, [Ask] AskPrice

  FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] cpsp WITH (NOLOCK)
  INNER JOIN [DWH_dbo].[Dim_Date] dd WITH (NOLOCK) ON cpsp.OccurredDateID = dd.DateKey
  JOIN [DWH_dbo].[Dim_Instrument] di ON di.InstrumentID = cpsp.InstrumentID  
  WHERE [OccurredDate] = <[Parameters].[Parameter 1]>
--OR [OccurredDate] = dateadd(year, -1, dateadd(day, 1, <[Parameters].[Parameter 1]>))
--OR [OccurredDate] = dateadd(year, -2, dateadd(day, 1, <[Parameters].[Parameter 1]>))
--OR [OccurredDate] = dateadd(year, -3, dateadd(day, 1, <[Parameters].[Parameter 1]>))
--OR [OccurredDate] = dateadd(year, -4, dateadd(day, 1, <[Parameters].[Parameter 1]>))
--OR [OccurredDate] = dateadd(year, -5, dateadd(day, 1, <[Parameters].[Parameter 1]>))
OR [OccurredDate] = dateadd(year, -1, <[Parameters].[Parameter 1]>)
OR [OccurredDate] = dateadd(year, -2, <[Parameters].[Parameter 1]>)
OR [OccurredDate] = dateadd(year, -3, <[Parameters].[Parameter 1]>)
OR [OccurredDate] = dateadd(year, -4, <[Parameters].[Parameter 1]>)
OR [OccurredDate] = dateadd(year, -5, <[Parameters].[Parameter 1]>)
--AND cpsp.isvalid = 1