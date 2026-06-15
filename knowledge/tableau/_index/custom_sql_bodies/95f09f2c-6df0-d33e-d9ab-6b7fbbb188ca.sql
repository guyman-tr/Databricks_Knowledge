SELECT
    bdad.[Year],
    bdad.[Month],
    CONCAT(bdad.[Year], '-', bdad.[Month]) AS [YrMth],
	EOMONTH(bdad.ModificationDate) [EOM_date],
    bdad.Region,
    bdad.[Country (customer)] AS [Country_OfCID],
    bdad.Regulation,
    bdad.FundingType,
    bdad.PaymentStatus,
    COUNT(DISTINCT bdad.DepositID) AS Count_DepID,
    COUNT(DISTINCT bdad.CID) [Uniq_CID],
    CAST(SUM(bdad.[Amount in $]) AS DECIMAL(12,2)) AS [Sum_Deposit]
FROM BI_DB_dbo.BI_DB_AllDeposits bdad
JOIN (SELECT 
        bdad1.DepositID AS [DepositID], 
        MAX(bdad1.ModificationDateID) AS [MaxModDate] 
      FROM BI_DB_dbo.BI_DB_AllDeposits bdad1 
      GROUP BY bdad1.DepositID) AS md 
      ON bdad.DepositID = md.DepositID AND bdad.ModificationDateID = md.MaxModDate
WHERE bdad.Year IN (2022, 2023)
and bdad.Region NOT IN ('eToro', 'Unknown')
GROUP BY
    bdad.[Year],
    bdad.[Month],
    CONCAT(bdad.[Year], '-', bdad.[Month]),
	EOMONTH(bdad.ModificationDate),
    bdad.Region,
    bdad.[Country (customer)],
    bdad.Regulation,
    bdad.FundingType,
    bdad.PaymentStatus