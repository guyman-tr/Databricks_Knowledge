SELECT b.InstrumentDisplayName, [Dealing_DailySpreadsAggregated].[hour0] AS [0],
  [Dealing_DailySpreadsAggregated].[hour10] AS [10],
  [Dealing_DailySpreadsAggregated].[hour11] AS [11],
  [Dealing_DailySpreadsAggregated].[hour12] AS [12],
  [Dealing_DailySpreadsAggregated].[hour13] AS [13],
  [Dealing_DailySpreadsAggregated].[hour14] AS [14],
  [Dealing_DailySpreadsAggregated].[hour15] AS [15],
  [Dealing_DailySpreadsAggregated].[hour16] AS [16],
  [Dealing_DailySpreadsAggregated].[hour17] AS [17],
  [Dealing_DailySpreadsAggregated].[hour18] AS [18],
  [Dealing_DailySpreadsAggregated].[hour19] AS [19],
  [Dealing_DailySpreadsAggregated].[hour1] AS [1],
  [Dealing_DailySpreadsAggregated].[hour20] AS [20],
  [Dealing_DailySpreadsAggregated].[hour21] AS [21],
  [Dealing_DailySpreadsAggregated].[hour22] AS [22],
  [Dealing_DailySpreadsAggregated].[hour23] AS [23],
  [Dealing_DailySpreadsAggregated].[hour2] AS [2],
  [Dealing_DailySpreadsAggregated].[hour3] AS [3],
  [Dealing_DailySpreadsAggregated].[hour4] AS [4],
  [Dealing_DailySpreadsAggregated].[hour5] AS [5],
  [Dealing_DailySpreadsAggregated].[hour6] AS [6],
  [Dealing_DailySpreadsAggregated].[hour7] AS [7],
  [Dealing_DailySpreadsAggregated].[hour8] AS [8],
  [Dealing_DailySpreadsAggregated].[hour9] AS [9],
  [Dealing_DailySpreadsAggregated].[AvgAskAt23] AS [AvgAskAt23],
  [Dealing_DailySpreadsAggregated].[Date] AS [Date],
  [Dealing_DailySpreadsAggregated].[InstrumentID] AS [InstrumentID],
  [Dealing_DailySpreadsAggregated].[InstrumentName] AS [InstrumentName],
  [Dealing_DailySpreadsAggregated].[InstrumentTypeID] AS [InstrumentTypeID],
  [Dealing_DailySpreadsAggregated].[LiquidityAccountID] AS [LiquidityAccountID],
  [Dealing_DailySpreadsAggregated].[Name] AS [Name],
  [Dealing_DailySpreadsAggregated].[count_hour0] AS [count0],
  [Dealing_DailySpreadsAggregated].[count_hour10] AS [count10],
  [Dealing_DailySpreadsAggregated].[count_hour11] AS [count11],
  [Dealing_DailySpreadsAggregated].[count_hour12] AS [count12],
  [Dealing_DailySpreadsAggregated].[count_hour13] AS [count13],
  [Dealing_DailySpreadsAggregated].[count_hour14] AS [count14],
  [Dealing_DailySpreadsAggregated].[count_hour15] AS [count15],
  [Dealing_DailySpreadsAggregated].[count_hour16] AS [count16],
  [Dealing_DailySpreadsAggregated].[count_hour17] AS [count17],
  [Dealing_DailySpreadsAggregated].[count_hour18] AS [count18],
  [Dealing_DailySpreadsAggregated].[count_hour19] AS [count19],
  [Dealing_DailySpreadsAggregated].[count_hour1] AS [count1],
  [Dealing_DailySpreadsAggregated].[count_hour20] AS [count20],
  [Dealing_DailySpreadsAggregated].[count_hour21] AS [count21],
  [Dealing_DailySpreadsAggregated].[count_hour22] AS [count22],
  [Dealing_DailySpreadsAggregated].[count_hour23] AS [count23],
  [Dealing_DailySpreadsAggregated].[count_hour2] AS [count2],
  [Dealing_DailySpreadsAggregated].[count_hour3] AS [count3],
  [Dealing_DailySpreadsAggregated].[count_hour4] AS [count4],
  [Dealing_DailySpreadsAggregated].[count_hour5] AS [count5],
  [Dealing_DailySpreadsAggregated].[count_hour6] AS [count6],
  [Dealing_DailySpreadsAggregated].[count_hour7] AS [count7],
  [Dealing_DailySpreadsAggregated].[count_hour8] AS [count8],
  [Dealing_DailySpreadsAggregated].[count_hour9] AS [count9],
  [Dealing_DailySpreadsAggregated].[updateDate] AS [updateDate]
FROM [Dealing_dbo].[Dealing_DailySpreadsAggregated] [Dealing_DailySpreadsAggregated]
JOIN DWH_dbo.Dim_Instrument b
ON b.InstrumentID  = [Dealing_DailySpreadsAggregated].InstrumentID