SELECT dt.FullDate
      ,t1.FiatAccount
      ,t2.FiatAccountStatuses
      ,t3.FiatAccountsProperties
      ,t4.FiatTransactions
      ,t5.FiatTransactionsStatuses
      ,t6.FiatBankAccount
      ,t7.FiatCards
      ,t8.FiatCardStatuses
      ,t9.FiatCurrencyBalances
      ,t10.FiatCurrencyBalancesStatuses
FROM(
SELECT FullDate 
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>) dt

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT fac.Id) AS 'FiatAccount' 
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatAccount fac WITH(NOLOCK) ON dd.FullDate = CAST(fac.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t1 ON t1.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT fst.Id) AS 'FiatAccountStatuses' 
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatAccountStatuses fst WITH(NOLOCK) ON dd.FullDate = CAST(fst.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t2 ON t2.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT fap.Id) AS 'FiatAccountsProperties'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatAccountsProperties fap WITH(NOLOCK) ON dd.FullDate = CAST(fap.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t3 ON t3.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT ftx.Id) AS 'FiatTransactions'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatTransactions ftx WITH(NOLOCK) ON dd.FullDate = CAST(ftx.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t4 ON t4.FullDate = dt.FullDate


LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT fts.Id) AS 'FiatTransactionsStatuses'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatTransactionsStatuses fts WITH(NOLOCK) ON dd.FullDate = CAST(fts.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t5 ON t5.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT fba.Id) AS 'FiatBankAccount'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatBankAccount fba WITH(NOLOCK) ON dd.FullDate = CAST(fba.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t6 ON t6.FullDate = dt.FullDate


LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT crd.Id) AS 'FiatCards'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatCards crd WITH(NOLOCK) ON dd.FullDate = CAST(crd.Created AS DATE)
WHERE dd.DateKey >= 20230201 AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t7 ON t7.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT crs.Id) AS 'FiatCardStatuses'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatCardStatuses crs WITH(NOLOCK) ON dd.FullDate = CAST(crs.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t8 ON t8.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT cbs.Id) AS 'FiatCurrencyBalances'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatCurrencyBalances cbs WITH(NOLOCK) ON dd.FullDate = CAST(cbs.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t9 ON t9.FullDate = dt.FullDate

LEFT JOIN(
SELECT dd.FullDate
      ,COUNT(DISTINCT css.Id) AS 'FiatCurrencyBalancesStatuses'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)
LEFT JOIN eMoney_dbo.FiatCurrencyBalancesStatuses css WITH(NOLOCK) ON dd.FullDate = CAST(css.Created AS DATE)
WHERE dd.DateKey >= <[Parameters].[Parameter 2]> AND dd.DateKey <= <[Parameters].[Parameter 3]>
GROUP BY dd.FullDate) t10 ON t10.FullDate = dt.FullDate