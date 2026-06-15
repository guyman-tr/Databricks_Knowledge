SELECT
d.CID,
e.State,
d.FundingType,
d.[FirstDepositDate] ,
  Sum(d.[Amount in $]) AS FirstDepositDayTotalAmount,
DATEDIFF(YEAR,e.BirthDate,getdate()) AS Age
FROM BI_DB_dbo.BI_DB_AllDeposits d
left join[BI_DB_dbo].BI_DB_CIDFirstDates e
on d.CID=e.CID
WHERE d.PaymentStatus IN ('Approved')
AND d.Regulation IN ('eToroUS', 'FinCEN', 'FinCEN+FINRA')

AND YEAR(e.BirthDate) BETWEEN YEAR(GETDATE()) - 69 AND YEAR(GETDATE()) - 50

and d.FundingType = 'PWMB'
AND CAST(d.[Deposit Time] AS DATE) = CAST(d.[FirstDepositDate] AS DATE)
 group by
 d.CID,
e.State,
d.FundingType,
d.[FirstDepositDate] ,
DATEDIFF(YEAR,e.BirthDate,getdate())
HAVING SUM(d.[Amount in $]) > 4999