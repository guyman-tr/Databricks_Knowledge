SELECT cdr.[DateID] AS [DateID],
  cdr.[Date] AS [Date],
  cdr.[InstrumentID] AS [InstrumentID],
  di.Name as InstrumentName,
  cdr.[PercentageOfReturn] AS [PercentageOfReturn],
  cdr.[UpdateDate] AS [UpdateDate],
  cdr.[percentageOf2week] AS [percentageOf2week],
  cdr.[percentageOf4week] AS [percentageOf4week]
FROM [Dealing_dbo].[Dealing_ClientDataRecurring] cdr
JOIN DWH_dbo.Dim_Instrument di on cdr.InstrumentID = di.InstrumentID