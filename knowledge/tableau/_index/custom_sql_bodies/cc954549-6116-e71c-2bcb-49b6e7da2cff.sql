SELECT [BI_DB_Stocks_Opportunities].[Avg_FirstActions] AS [Avg_FirstActions],
  [BI_DB_Stocks_Opportunities].[Avg_UsersOpen] AS [Avg_UsersOpen],
  [BI_DB_Stocks_Opportunities].[Country] AS [Country],
  [BI_DB_Stocks_Opportunities].[Date] AS [Date],
  [BI_DB_Stocks_Opportunities].[Exchange] AS [Exchange],
  [BI_DB_Stocks_Opportunities].[FirstActions] AS [FirstActions],
  [BI_DB_Stocks_Opportunities].[Gain_30Days] AS [Gain_30Days],
  [BI_DB_Stocks_Opportunities].[Gain_Yesterday] AS [Gain_Yesterday],
  [BI_DB_Stocks_Opportunities].[Indicator] AS [Indicator],
  [BI_DB_Stocks_Opportunities].[IndustryGroup] AS [IndustryGroup],
  [Custom SQL Query].[InstrumentID] AS [InstrumentID (Custom SQL Query)],
  [BI_DB_Stocks_Opportunities].[InstrumentID] AS [InstrumentID],
  [BI_DB_Stocks_Opportunities].[InstrumentName] AS [InstrumentName],
  [BI_DB_Stocks_Opportunities].[Region] AS [Region],
  [Custom SQL Query].[Symbol] AS [Symbol],
  [BI_DB_Stocks_Opportunities].[UpdateDate] AS [UpdateDate],
  [BI_DB_Stocks_Opportunities].[UsersOpen] AS [UsersOpen]
FROM [BI_DB_dbo].[BI_DB_Stocks_Opportunities] [BI_DB_Stocks_Opportunities]
  LEFT JOIN (
  select Name As Symbol
         ,InstrumentID
   from DWH_dbo.Dim_Instrument
) [Custom SQL Query] ON ([BI_DB_Stocks_Opportunities].[InstrumentID] = [Custom SQL Query].[InstrumentID])