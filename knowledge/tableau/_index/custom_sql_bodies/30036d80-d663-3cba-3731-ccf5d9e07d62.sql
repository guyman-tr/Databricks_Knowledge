SELECT [Dealing_MaxPositionUnits].[Currency] AS [Currency],
  [Dealing_MaxPositionUnits].[Date] AS [Date],
  [Dealing_MaxPositionUnits].[InstrumentDisplayName] AS [InstrumentDisplayName],
  [Dealing_MaxPositionUnits].[InstrumentID] AS [InstrumentID],
  [DI].[InstrumentTypeID] as [InstrumentTypeID],
  [DI].[InstrumentType] as [InstrumentType], 
  [Dealing_MaxPositionUnits].[LastPrice] AS [LastPrice],
  [Dealing_MaxPositionUnits].[MaxPositionUnitsXaip.LastPrice] AS [MaxPositionUnitsXaip.LastPrice],
  [Dealing_MaxPositionUnits].[MaxPositionUnits] AS [MaxPositionUnits],
  [Dealing_MaxPositionUnits].[SymbolFull] AS [SymbolFull],
  [Dealing_MaxPositionUnits].[Symbol] AS [Symbol],
  [Dealing_MaxPositionUnits].[UpdateDate] AS [UpdateDate]
FROM [Dealing_dbo].[Dealing_MaxPositionUnits] [Dealing_MaxPositionUnits]
left join [DWH_dbo].[Dim_Instrument] [DI]
 on [Dealing_MaxPositionUnits].[InstrumentID] = [DI].[InstrumentID]