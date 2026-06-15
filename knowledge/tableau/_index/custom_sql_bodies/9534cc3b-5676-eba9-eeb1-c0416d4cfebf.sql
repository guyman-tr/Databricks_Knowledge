SELECT dd.FullDate
      ,COUNT(DISTINCT ftx.Id) AS 'FiatTransactions'
      ,COUNT(DISTINCT fts.Id) AS 'FiatTransactionsStatuses'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN [eMoney_dbo].[FiatTransactions] ftx WITH(NOLOCK) ON dd.FullDate = CAST(ftx.Created AS DATE)
LEFT JOIN [eMoney_dbo].[FiatTransactionsStatuses] fts WITH(NOLOCK) ON dd.FullDate = CAST(fts.Created AS DATE)
WHERE dd.DateKey >= CAST(CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112) AS INT)
      AND dd.DateKey < CAST(CONVERT(CHAR(8), GETDATE(), 112) AS INT)
GROUP BY dd.FullDate