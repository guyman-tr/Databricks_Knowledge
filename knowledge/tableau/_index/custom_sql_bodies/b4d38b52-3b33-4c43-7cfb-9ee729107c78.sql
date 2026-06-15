SELECT 
   GCID  
 ,  efrbn.Balance 
 ,  efrbn.BalanceUSD 
  , efrbn.Country
  , efrbn.Regulation
 , efrbn.BalanceDate
 , efrbn.BalanceDateID
 , efrbn.CryptoName
  FROM EXW.dbo.EXW_FinanceReportsBalancesNew efrbn
 WHERE 1=1
 --efrbn.VerificationLevelID =3 
 --AND efrbn.IsValidCustomer =1 
 AND efrbn.IsTestAccount =0 
 AND efrbn.CountryID =79  
-- AND efrbn.BalanceDateID =@DateID
AND efrbn.BalanceUSD >0  -- to remove xtokens
AND efrbn.BalanceUSD > <[Parameters].[Parameter 1]>
 AND efrbn.ComplianceClosureEvent =0 
AND efrbn.AMLClosureEvent =0
 
AND efrbn.BalanceDate =  <[Parameters].[Parameter 2]>