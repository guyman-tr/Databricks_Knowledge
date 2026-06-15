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
       ,ABS(dw.Amount)     AS AmountLocal
       ,fca.ActionTypeID
       ,mdt.HolderCurrencyDesc            AS Currency
       ,mda.Country
       ,mda.ClubCategory
       ,(dw.BaseExchangeRate - dw.ExchangeRate) * dw.Amount AS ConversionFeeInDollars
       ,CAST(fca.Occurred AS DATE) AS OccurredDate
       ,'Local to USD' AS Direction

FROM DWH_dbo.Fact_CustomerAction fca

INNER JOIN eMoney_dbo.eMoney_Dim_Account mda 
       ON fca.GCID = mda.GCID

INNER JOIN (
        SELECT  MAX(s.HolderCurrencyDesc) AS HolderCurrencyDesc,
                s.CID
        FROM eMoney_dbo.eMoney_Dim_Transaction s
        GROUP BY s.CID
) mdt  
       ON fca.RealCID = mdt.CID

LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee dw 
       ON fca.DepositID = dw.DepositWithdrawID 
      AND dw.TransactionType = 'Deposit'

WHERE fca.ActionTypeID = 7
  AND fca.MoveMoneyReasonID = 6
  AND mda.IsValidETM = 1
  AND fca.FundingTypeID = 33
  AND fca.DateID >= 20250401
  AND fca.Occurred >= DATEADD(YEAR,-1, CAST(GETDATE() AS DATE))


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
       ,ABS(dw.Amount)     AS AmountLocal
       ,fca.ActionTypeID
       ,mdt.HolderCurrencyDesc            AS Currency
       ,mda.Country
       ,mda.ClubCategory
       ,(dw.BaseExchangeRate - dw.ExchangeRate) * dw.Amount AS ConversionFeeInDollars
       ,CAST(fca.Occurred AS DATE) AS OccurredDate
       ,'USD to Local' AS Direction

FROM DWH_dbo.Fact_CustomerAction fca

INNER JOIN eMoney_dbo.eMoney_Dim_Account mda 
       ON fca.GCID = mda.GCID

INNER JOIN (
        SELECT  MAX(s.HolderCurrencyDesc) AS HolderCurrencyDesc,
                s.CID
        FROM eMoney_dbo.eMoney_Dim_Transaction s
        GROUP BY s.CID
) mdt  
       ON fca.RealCID = mdt.CID

LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee dw 
       ON fca.WithdrawID = dw.DepositWithdrawID 
      AND dw.TransactionType = 'Withdraw'

WHERE fca.ActionTypeID = 8
  AND fca.MoveMoneyReasonID = 6
  AND mda.IsValidETM = 1
  AND fca.FundingTypeID = 33
  AND fca.DateID >= 20250401
  AND fca.Occurred >= DATEADD(YEAR,-1, CAST(GETDATE() AS DATE))