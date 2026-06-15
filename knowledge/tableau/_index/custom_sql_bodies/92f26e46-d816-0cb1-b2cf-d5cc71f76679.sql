SELECT COUNT(DISTINCT cb.GCID)  'Users Number Per Crypto'
, cb.CryptoId
, cb.CryptoName
, cb.Country
, cb.IsTestAccount
, cb.Regulation
, edu.VerificationLevelID
, edu.Region 
, edu.IsValidCustomer
, SUM(CASE WHEN bkg.WalletId IS null THEN cb.BalanceUSD ELSE efb.BalanceUSD END) 'Balance USD Per Crypto'
FROM  EXW.dbo.EXW_UserCalculatedBalance cb
LEFT JOIN EXW.dbo.EXW_FactBalance efb ON cb.CryptoId = efb.CryptoId AND cb.WalletId = efb.WalletID AND efb.FullDateID = cb.BalanceDateId
LEFT JOIN  BalanceKnownGaps bkg ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
JOIN EXW.dbo.EXW_DimUser edu  ON cb.GCID = edu.GCID 
WHERE 1=1
AND cb.BalanceDateId =CONVERT(VARCHAR(8), getdate(), 112)  
GROUP BY 
cb.CryptoId
, cb.CryptoName
, cb.Country
, cb.IsTestAccount
, cb.Regulation
, edu.VerificationLevelID
, edu.Region
 ,edu.IsValidCustomer