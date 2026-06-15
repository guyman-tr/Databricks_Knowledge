SELECT 
    fca.DateID,
    CAST(fca.Occurred AS DATE) AS Occurred,
    fca.RealCID,
    SUM(CASE WHEN fca.ActionTypeID = 1 AND di.InstrumentTypeID IN (6, 5, 10) AND fca.Leverage = 1  THEN 1 ELSE 0 END) AS Open_Not_LC_TXs,
    SUM(CASE WHEN fca.ActionTypeID = 4 AND di.InstrumentTypeID IN (6, 5, 10) AND fca.Leverage = 1  THEN 1 ELSE 0 END) AS Close_Not_LC_TXs,
    SUM(CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END) AS Open_LC_TXs,
    SUM(CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0 END) AS Close_LC_TXs,
    SUM(CASE WHEN fca.ActionTypeID = 1 AND di.InstrumentTypeID IN (6, 5, 10) AND fca.Leverage = 1  THEN ABS(fca.Amount) ELSE 0 END) AS Open_Not_LC_Amount,
    SUM(CASE WHEN fca.ActionTypeID = 4 AND di.InstrumentTypeID IN (6, 5, 10) AND fca.Leverage = 1  THEN ABS(fca.Amount) ELSE 0 END) AS Close_Not_LC_Amount,
    SUM(CASE WHEN fca.ActionTypeID = 44 THEN ABS(fca.Amount) ELSE 0 END) AS Open_LC_Amount,
    SUM(CASE WHEN fca.ActionTypeID = 45 THEN ABS(fca.Amount) ELSE 0 END) AS Close_LC_Amount,
    SUM(CASE WHEN fca.ActionTypeID = 7 AND fca.FundingTypeID = 33 THEN ISNULL(de.PIPsCalculation, 0) ELSE 0 END) AS Deposit_Fees_eTM,
    SUM(CASE WHEN fca.ActionTypeID = 8 AND fca.FundingTypeID = 33 THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Withdraw_Fees_eTM,
    SUM(CASE WHEN fca.ActionTypeID = 44 AND fca.FundingTypeID = 33 THEN ISNULL(de.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_eTM,
    SUM(CASE WHEN fca.ActionTypeID = 45 AND fca.FundingTypeID = 33 THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_eTM
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN DWH_dbo.Dim_Customer dc 
    ON fca.GCID = dc.GCID 
    AND dc.IsValidCustomer = 1
INNER JOIN DWH_dbo.Dim_Instrument di 
    ON fca.InstrumentID = di.InstrumentID
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr 
    ON mdcr.CountryID = dc.CountryID
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee de 
    ON fca.DepositID = de.DepositWithdrawID 
    AND de.TransactionType = 'Deposit' 
    AND de.DateID >= CONVERT(INT, FORMAT(DATEADD(MONTH, -1, CAST(de.Occurred AS DATE)), 'yyyyMMdd'))
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee wi 
    ON fca.WithdrawID = wi.DepositWithdrawID 
    AND wi.TransactionType = 'Withdraw' 
    AND wi.DateID >= CONVERT(INT, FORMAT(DATEADD(MONTH, -1, CAST(wi.Occurred AS DATE)), 'yyyyMMdd'))
WHERE fca.ActionTypeID IN (1, 4, 44, 45) 
    AND CAST(fca.Occurred AS DATE) >= DATEADD(MONTH, -1, CAST(fca.Occurred AS DATE))
GROUP BY 
    fca.DateID,
    CAST(fca.Occurred AS DATE),
    fca.RealCID