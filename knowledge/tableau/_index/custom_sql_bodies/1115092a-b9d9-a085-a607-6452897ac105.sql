SELECT
    mda.Country,
    mda.Club,
  CASE
    WHEN AccountSubProgramID IN (1,2,4,8)              THEN 'UK'
    WHEN AccountSubProgramID IN (5,6,7,9,11,12)        THEN 'EU'
    WHEN AccountSubProgramID IN (13,14)                THEN 'AU'
    WHEN AccountSubProgramID IN (15,16)                THEN 'DKK'
    ELSE 'UNKNOWN' 
END AS IBAN_Region,
   SUM(CASE WHEN fca.ActionTypeID = 44 AND CAST(fca.Occurred AS DATE) = CAST(GETDATE() - 1 AS DATE) THEN ISNULL(f.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_Yesterday,
  SUM(CASE WHEN fca.ActionTypeID = 45 AND CAST(fca.Occurred AS DATE) = CAST(GETDATE() - 1 AS DATE) THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_Yesterday,
   SUM(CASE WHEN fca.ActionTypeID = 44 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 7 AS DATE) THEN ISNULL(f.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_7days,
  SUM(CASE WHEN fca.ActionTypeID = 45 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 7 AS DATE) THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_7days,
  SUM(CASE WHEN fca.ActionTypeID = 44 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 30 AS DATE) THEN ISNULL(f.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_Last_30_Days,
SUM(CASE WHEN fca.ActionTypeID = 45 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 30 AS DATE) THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_Last_30_Days,
SUM(CASE WHEN fca.ActionTypeID = 44 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 365 AS DATE) THEN ISNULL(f.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_Last_365_Days,
SUM(CASE WHEN fca.ActionTypeID = 45 AND CAST(fca.Occurred AS DATE) >= CAST(GETDATE() - 365 AS DATE) THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_Last_365_Days,
  SUM(CASE WHEN fca.ActionTypeID = 44 THEN ISNULL(f.PIPsCalculation, 0) ELSE 0 END) AS Open_Fees_Total,
  SUM(CASE WHEN fca.ActionTypeID = 45 THEN ISNULL(wi.PIPsCalculation, 0) ELSE 0 END) AS Close_Fees_Total
   FROM DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH (NOLOCK)
    ON fca.RealCID = mda.CID 
    AND mda.IsValidETM=1 
    AND mda.GCID_Unique_Count=1 
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee f WITH (NOLOCK)
    ON fca.DepositID = f.DepositWithdrawID
    AND f.TransactionType = 'Deposit'
    AND f.DateID >= 20240401
LEFT JOIN BI_DB_dbo.BI_DB_DepositWithdrawFee wi WITH (NOLOCK) 
    ON fca.WithdrawID = wi.DepositWithdrawID
    AND wi.TransactionType = 'Withdraw'
    AND wi.DateID >= 20240401
WHERE 
    fca.FundingTypeID = 33 
    AND fca.ActionTypeID IN (44, 45)
   AND fca.Occurred >= '2024-04-01 00:00:00'
		GROUP BY 
	 mda.Country,
    mda.Club,
   CASE
    WHEN AccountSubProgramID IN (1,2,4,8)              THEN 'UK'
    WHEN AccountSubProgramID IN (5,6,7,9,11,12)        THEN 'EU'
    WHEN AccountSubProgramID IN (13,14)                THEN 'AU'
    WHEN AccountSubProgramID IN (15,16)                THEN 'DKK'
    ELSE 'UNKNOWN' 
END