SELECT
count (DISTINCT fbw.WithdrawID) AS Cashouts,
YEAR(fbw.ModificationDate) AS Year,
format(fbw.ModificationDate,'yyyyMM') AS YearMonth,
MONTH(fbw.ModificationDate) AS Month

FROM DWH_dbo.Fact_BillingWithdraw fbw
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbw.CID
WHERE fbw.CashoutStatusID_Withdraw=3 AND fbw.CashoutStatusID_Funding=3
AND fbw.CashoutReasonID not in (12, 15)
AND dc.IsValidCustomer=1
and fbw.ModificationDate>='20200101'
GROUP BY 
YEAR(fbw.ModificationDate),
MONTH(fbw.ModificationDate),
format(fbw.ModificationDate,'yyyyMM')