SELECT 
   COUNT(DISTINCT GCID )Users
, efrbn.Country
, efrbn.Regulation
 , DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate)  EOW_Friday
 FROM EXW.dbo.EXW_FinanceReportsBalancesNew efrbn
 WHERE 1=1
--and efrbn.VerificationLevelID =3 
-- AND efrbn.IsValidCustomer =1 
 AND efrbn.IsTestAccount =0 
 AND efrbn.CountryID =79  
-- AND efrbn.BalanceDateID =@DateID
 AND efrbn.Balance>0
 AND efrbn.ComplianceClosureEvent =0 
AND efrbn.AMLClosureEvent =0
AND efrbn.BalanceDate=DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate) 
AND efrbn.BalanceDate >=CAST(GETDATE()-36 AS DATE)
GROUP BY 
  efrbn.BalanceDate
  , efrbn.Country
, efrbn.Regulation
 , DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate)