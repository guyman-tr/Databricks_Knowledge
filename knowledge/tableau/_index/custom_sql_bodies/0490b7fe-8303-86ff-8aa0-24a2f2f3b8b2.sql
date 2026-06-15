SELECT [TanganyDailyTransactions].[toAccountId] AS [TanganyID] ,
[TanganyDailyTransactions].[assetId] AS [assetId],
  [TanganyDailyTransactions].[euroValue] AS [euroValue],
  [TanganyDailyTransactions].[fillDate] AS [fillDate],
  [TanganyDailyTransactions].[id] AS [id],
  [TanganyDailyTransactions].[marketMakerTxId] AS [marketMakerTxId],
  [TanganyDailyTransactions].[reference] AS [reference],
  [TanganyDailyTransactions].[rn] AS [rn],
  
  [TanganyDailyTransactions].[valueDate] AS [valueDate],
  [TanganyDailyTransactions].[value] AS [value]
FROM [dbo].[TanganyDailyTransactions] [TanganyDailyTransactions]

union  
SELECT
  [TanganyDailyTransactions].[fromAccountId] AS [TanganyID], [TanganyDailyTransactions].[assetId] AS [assetId],
  [TanganyDailyTransactions].[euroValue] AS [euroValue],
  [TanganyDailyTransactions].[fillDate] AS [fillDate],

  [TanganyDailyTransactions].[id] AS [id],
  [TanganyDailyTransactions].[marketMakerTxId] AS [marketMakerTxId],
  [TanganyDailyTransactions].[reference] AS [reference],
  [TanganyDailyTransactions].[rn] AS [rn],
  [TanganyDailyTransactions].[valueDate] AS [valueDate],
  [TanganyDailyTransactions].[value] AS [value]
FROM [dbo].[TanganyDailyTransactions] [TanganyDailyTransactions]