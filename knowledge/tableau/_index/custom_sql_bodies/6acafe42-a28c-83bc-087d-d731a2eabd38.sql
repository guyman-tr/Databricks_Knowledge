SELECT  fca.HistoryID
       ,fca.DepositID
	   ,fca.WithdrawID
	   ,fca.WithdrawPaymentID
	   ,fca.Occurred
	   ,fca.UpdateDate
       ,fca.GCID
	   ,fca.RealCID
	   ,fca.Amount
	   ,ABS(dw.AmountUSD)  AS AmountUSD
	   ,ABS(dw.Amount ) AS Amount_GBP_Euro
	   ,fca.ActionTypeID
       ,mda.CurrencyBalanceISODesc
	   ,mda.Country
	   ,mda.ClubCategory
	   ,(dw.BaseExchangeRate-dw.ExchangeRate)*dw.Amount as ConversionFeeInDollars
	   ,CAST(fca.Occurred AS DATE) AS OccurredDate
	   ,CASE WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer USD > GBP'
	         WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer USD > EUR'
			 WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer GBP > USD'
	         WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer EUR > USD'
			 ELSE 'Error' END AS AccountStatements
		,CASE WHEN fca.ActionTypeID = 8 THEN 'Transaction Type- Transfer USD > GBP/EUR'
			 WHEN fca.ActionTypeID = 7 THEN 'Transaction Type- Transfer GBP/EUR > USD'
			 ELSE 'Error' END AS AccountStatementsGroup
			 ,CASE WHEN fca.ActionTypeID = 8 THEN 'Iban transfer USD > GBP/EUR'
			 WHEN fca.ActionTypeID = 7 THEN 'Iban transfer GBP/EUR > USD'
			 ELSE 'Error' END AS Iban_transfer
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda ON fca.GCID = mda.GCID
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee dw ON fca.DepositID=dw.DepositWithdrawID AND dw.TransactionType='Deposit'
WHERE fca.ActionTypeID =7 AND fca.MoveMoneyReasonID=6 AND  fca.FundingTypeID=33 AND fca.DateID>=20250401 AND fca.RealCID=<[Parameters].[Parameter 1]>

UNION ALL

SELECT  fca.HistoryID
       ,fca.DepositID
	   ,fca.WithdrawID
	   ,fca.WithdrawPaymentID
	   ,fca.Occurred
	   ,fca.UpdateDate
       ,fca.GCID
	   ,fca.RealCID
	   ,fca.Amount
	   ,ABS(dw.AmountUSD)  AS AmountUSD
	   ,ABS(dw.Amount ) AS Amount_GBP_Euro
	   ,fca.ActionTypeID
       ,mda.CurrencyBalanceISODesc
	   ,mda.Country
	   ,mda.ClubCategory
	   ,(dw.BaseExchangeRate-dw.ExchangeRate)*dw.Amount as ConversionFeeInDollars
	   ,CAST(fca.Occurred AS DATE) AS OccurredDate
	   ,CASE WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer USD > GBP'
	         WHEN fca.ActionTypeID = 8 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer USD > EUR'
			 WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='GBP' THEN 'Transaction Type- Transfer GBP > USD'
	         WHEN fca.ActionTypeID = 7 AND mda.CurrencyBalanceISODesc='EUR' THEN 'Transaction Type- Transfer EUR > USD'
			 ELSE 'Error' END AS AccountStatements
		,CASE WHEN fca.ActionTypeID = 8 THEN 'Transaction Type- Transfer USD > GBP/EUR'
			 WHEN fca.ActionTypeID = 7 THEN 'Transaction Type- Transfer GBP/EUR > USD'
			 ELSE 'Error' END AS AccountStatementsGroup
			 	,CASE WHEN fca.ActionTypeID = 8 THEN 'Iban transfer USD > GBP/EUR'
			 WHEN fca.ActionTypeID = 7 THEN 'Iban transfer GBP/EUR > USD'
			 ELSE 'Error' END AS Iban_transfer
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda ON fca.GCID = mda.GCID
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee dw ON fca.WithdrawID=dw.DepositWithdrawID AND dw.TransactionType='Withdraw'
WHERE fca.ActionTypeID =8 AND fca.MoveMoneyReasonID=6 AND fca.FundingTypeID=33 AND fca.DateID>=20250401 AND fca.RealCID=<[Parameters].[Parameter 1]>