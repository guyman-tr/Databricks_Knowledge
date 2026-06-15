SELECT
count (DISTINCT fbw.DepositID) AS Deposits,
YEAR(fbw.ModificationDate) AS Year,
MONTH(fbw.ModificationDate) AS Month,
dft.Name AS FundingType,
sum(case when dft.Name in ('WireTransfer') THEN 1 ELSE 0 END) AS Wires,
format(fbw.ModificationDate,'yyyyMM') AS YearMonth
FROM DWH_dbo.Fact_BillingDeposit fbw
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbw.CID
JOIN DWH_dbo.Dim_FundingType dft ON dft.FundingTypeID=fbw.FundingTypeID
WHERE fbw.PaymentStatusID=2  --Approved
AND dc.IsValidCustomer=1
and fbw.ModificationDate>='20200101'
GROUP BY 
YEAR(fbw.ModificationDate),
MONTH(fbw.ModificationDate),
dft.Name,
format(fbw.ModificationDate,'yyyyMM')