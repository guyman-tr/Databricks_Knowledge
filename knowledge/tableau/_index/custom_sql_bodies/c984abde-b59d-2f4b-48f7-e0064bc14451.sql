SELECT 
  COUNT( edu. GCID )'Total Number of Users'
  ,SUM( CASE WHEN efb.BalanceUSD >0 THEN 1 ELSE 0 END) 'Non Zero User'
--, edu.RealCID
, edu.Country
, edu.IsTestAccount
, edu.Regulation
, edu.Region
, edu.VerificationLevelID
, edu.IsValidCustomer
, SUM(efb.BalanceUSD)'Balance USD'
FROM EXW.dbo.EXW_DimUser edu 
JOIN 
(SELECT cb.GCID
, SUM(CASE WHEN bkg.WalletId IS null THEN cb.BalanceUSD ELSE efb.BalanceUSD END) BalanceUSD 
FROM  EXW.dbo.EXW_UserCalculatedBalance cb
LEFT JOIN EXW.dbo.EXW_FactBalance efb ON cb.CryptoId = efb.CryptoId AND cb.WalletId = efb.WalletID AND efb.FullDateID = cb.BalanceDateId
LEFT JOIN  BalanceKnownGaps bkg ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
WHERE 1=1
AND cb.BalanceDateId =CONVERT(VARCHAR(8), getdate(), 112)  
GROUP BY cb.GCID) efb 
ON edu.GCID=efb.GCID 

 GROUP BY 
 edu.Country
, edu.IsTestAccount
, edu.Regulation
, edu.Region
, edu.VerificationLevelID
, edu.IsValidCustomer