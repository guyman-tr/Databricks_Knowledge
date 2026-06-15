SELECT 
  COUNT(GCID )Users
 , SUM(efrbn.Balance)BalanceCrypto
 , SUM(efrbn.BalanceUSD)BalanceUSD
  , efrbn.Country
  , efrbn.Regulation
 , efrbn.BalanceDate
 , efrbn.BalanceDateID
 , DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate)  EOW_Friday
 
 , efrbn.CryptoName
  FROM EXW.dbo.EXW_FinanceReportsBalancesNew efrbn
 WHERE 1=1
 --efrbn.VerificationLevelID =3 
 --AND efrbn.IsValidCustomer =1 
 AND efrbn.IsTestAccount =0 
 AND efrbn.CountryID =79  
-- AND efrbn.BalanceDateID =@DateID
 AND efrbn.Balance>0
 AND efrbn.ComplianceClosureEvent =0 
AND efrbn.AMLClosureEvent =0
AND efrbn.BalanceDate=DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate) 
AND efrbn.BalanceDate >=CAST(GETDATE()-36 AS DATE)
GROUP BY 
 efrbn.Country
 , efrbn.Regulation
 , efrbn.BalanceDate
 , efrbn.BalanceDateID
 , DATEADD(dd, 6-(DATEPART(dw, efrbn.BalanceDate)),  efrbn.BalanceDate)  
 , efrbn.CryptoName