SELECT [Date], SUM([ChangeInUnrealizedZero]) AS [ChangeInUnrealizedZero]
FROM [BI_DB_dbo].[BI_DB_DailyZero_TreeSize_NEW]
WHERE [IsCFD] = 1 AND [Regulation] = 'FCA' AND [Date] >= '20230101'
GROUP BY [Date]