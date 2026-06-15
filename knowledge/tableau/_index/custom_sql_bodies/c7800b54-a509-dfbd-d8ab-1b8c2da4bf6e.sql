SELECT a.AccountStatements
      ,a.ClubCategory
	  ,a.Country
      ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-2 THEN 1 ELSE 0 END) AS 'Last Day TXs'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-7 THEN 1 ELSE 0 END) AS 'Last 7 Days TXs'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-30 THEN 1 ELSE 0 END) AS 'Last 30 Days TXs'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-365 THEN 1 ELSE 0 END) AS 'Last 365 Days TXs'

	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-2 THEN a.Amount ELSE 0 END) AS 'Last Day Amount'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-7 THEN a.Amount ELSE 0 END) AS 'Last 7 Days Amount'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-30 THEN a.Amount ELSE 0 END) AS 'Last 30 Days Amount'
	  ,SUM(CASE WHEN a.OccurredDate >= GETDATE ()-365 THEN a.Amount ELSE 0 END) AS 'Last 365 Days Amount'
	       
FROM (
SELECT fca.*
       ,mda.CurrencyBalanceISODesc
	   ,mda.Country
	   ,mda.ClubCategory
	   ,CAST(fca.Occurred AS DATE) AS OccurredDate
	   ,CASE WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer USD > GBP'
	         WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer USD > EUR'
			 WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer GBP > USD'
	         WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer EUR > USD'
			 ELSE 'Error' END AS AccountStatements
		,CASE WHEN fca.ActionTypeID = 8 THEN 'Transaction Type- Transfer USD > GBP/EUR'
			 WHEN fca.ActionTypeID = 7 THEN 'Transaction Type- Transfer GBP/EUR > USD'
			 ELSE 'Error' END AS AccountStatementsGroup
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda ON fca.GCID = mda.GCID
WHERE fca.ActionTypeID IN (7,8) AND fca.MoveMoneyReasonID=6 AND mda.IsValidETM=1 AND fca.FundingTypeID=33) a
GROUP BY  a.AccountStatements
      ,a.ClubCategory
	  ,a.Country