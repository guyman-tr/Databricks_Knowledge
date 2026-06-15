SELECT [Dealing_HighFrequencyAbuse].[ADV] AS [ADV],
  [Dealing_HighFrequencyAbuse].[CountOver] AS [CountOver],
  [Dealing_HighFrequencyAbuse].[CountTotal] AS [CountTotal],
  [Dealing_HighFrequencyAbuse].[CountUnder] AS [CountUnder],
  [Dealing_HighFrequencyAbuse].[DateID] AS [DateID],
  [Dealing_HighFrequencyAbuse].[Date] AS [Date],
  [Dealing_HighFrequencyAbuse].[HighFrequencyVolume] AS [HighFrequencyVolume],
  [Dealing_HighFrequencyAbuse].[HighFrequencyZero] AS [HighFrequencyZero],
  [Dealing_HighFrequencyAbuse].[InstrumentID] AS [InstrumentID],
  [Dealing_HighFrequencyAbuse].[InstrumentName] AS [InstrumentName],
   di.InstrumentType as [Asset Class],
  [Dealing_HighFrequencyAbuse].[InstrumentRealizedZero] AS [InstrumentRealizedZero],
  [Dealing_HighFrequencyAbuse].[InstrumentVolume] AS [InstrumentVolume],
  [Dealing_HighFrequencyAbuse].[IsUS] AS [IsUS],
  [Dealing_HighFrequencyAbuse].[LifeSpan] AS [LifeSpan],
  [Dealing_HighFrequencyAbuse].[LiquidityAccountName] AS [LiquidityAccountName],
  [Dealing_HighFrequencyAbuse].[Real_CFD] AS [Real_CFD],
  [Dealing_HighFrequencyAbuse].[UpdateDate] AS [UpdateDate],
  [Dealing_HighFrequencyAbuse].[eToroAdvRatio] AS [eToroAdvRatio]
FROM [dbo].[Dealing_HighFrequencyAbuse] [Dealing_HighFrequencyAbuse]
Join DWH..Dim_Instrument di on [Dealing_HighFrequencyAbuse].InstrumentID = di.InstrumentID