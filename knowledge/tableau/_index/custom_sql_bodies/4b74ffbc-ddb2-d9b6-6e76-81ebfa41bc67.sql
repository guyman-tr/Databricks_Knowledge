SELECT [TanganyInitialBalance].[toAccountId] AS [TanganyID] ,
[TanganyInitialBalance].[FromAccountId] ,
[TanganyInitialBalance].[assetId] AS [assetId],
  [TanganyInitialBalance].[euroValue] AS [euroValue],
  [TanganyInitialBalance].[fillDate] AS [fillDate],
  [TanganyInitialBalance].[id] AS [id],
  [TanganyInitialBalance].[marketMakerTxId] AS [marketMakerTxId],
  [TanganyInitialBalance].[reference] AS [reference],
  [TanganyInitialBalance].[rn] AS [rn],
  
  [TanganyInitialBalance].[valueDate] AS [valueDate],
  [TanganyInitialBalance].[value] AS [value]
FROM [dbo].[TanganyInitialBalance] [TanganyInitialBalance]