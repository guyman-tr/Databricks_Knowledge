SELECT 
    YEAR(fca.Occurred) AS Year_,
    CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, fca.Occurred), CAST(fca.Occurred AS DATE)) AS DATE) AS Week_Start_Date,

    SUM(CASE WHEN fca.FundingTypeID = 33 AND fca.ActionTypeID = 44 THEN ISNULL(f.PIPsCalculation, 0) END) AS 'Open_Position_LC_(Deposit)_pips_calc_fee',
    SUM(CASE WHEN fca.ActionTypeID = 7 THEN ISNULL(f.PIPsCalculation, 0) END) AS 'Deposit_pipc_calc_fee',
    SUM(CASE WHEN fca.FundingTypeID = 33 AND fca.ActionTypeID = 45 THEN ISNULL(wi.PIPsCalculation, 0) END) AS 'Close_Position_LC_(Withdraw)_pips_calc_fee',
    SUM(CASE WHEN fca.ActionTypeID = 8 THEN ISNULL(wi.PIPsCalculation, 0) END) AS 'Withdraw_pips_calc_fee'

FROM DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)

INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH (NOLOCK)
    ON fca.RealCID = mda.CID 
    AND mda.IsValidETM = 1 
    AND mda.GCID_Unique_Count = 1 

LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee f WITH (NOLOCK)
    ON fca.DepositID = f.DepositWithdrawID
    AND f.TransactionType = 'Deposit'
    AND f.DateID >= 20240401

LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee wi WITH (NOLOCK)
    ON fca.WithdrawID = wi.DepositWithdrawID
    AND wi.TransactionType = 'Withdraw'
    AND wi.DateID >= 20240401

WHERE    
    fca.ActionTypeID IN (44, 45, 7, 8)
    AND fca.Occurred >= '2024-04-01 00:00:00'

GROUP BY 
    YEAR(fca.Occurred), 
    CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, fca.Occurred), CAST(fca.Occurred AS DATE)) AS DATE)