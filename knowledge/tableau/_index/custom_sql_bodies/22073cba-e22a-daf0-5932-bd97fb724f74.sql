SELECT 
count (bdad.DepositID) AS #OfDeposits,
CASE WHEN bdad.IsFTD=0 THEN 'Redeposit' ELSE 'FTD' END AS [Redeposit/FTD],
CAST(bdad.ModificationDate AS DATE) AS DepositDate,
bdad.FundingType
FROM BI_DB_dbo.BI_DB_AllDeposits bdad
WHERE bdad.ModificationDate>=DATEADD(MONTH, -12, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))    
AND bdad.PaymentStatus IN ('Approved')
GROUP BY 
CASE WHEN bdad.IsFTD=0 THEN 'Redeposit' ELSE 'FTD' END ,
CAST(bdad.ModificationDate AS DATE),
bdad.FundingType