SELECT sub.CryptoName 'Crypto Name',sub.USD, sub.[Users Per Coin]
, sub.RealUser
, sub.Regulation
--, CASE WHEN sub. IsTestAccount=1 THEN 'Y' ELSE 'N' END TestUser
FROM 
(SELECT
 SUM(CASE WHEN bkg.WalletId IS NULL THEN cb.BalanceUSD ELSE efb.BalanceUSD END) USD
, COUNT(DISTINCT cb.GCID)  'Users Per Coin'
, cb.CryptoName
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, cb.Regulation
FROM  EXW.dbo.EXW_UserCalculatedBalance  cb  WITH (NOLOCK)
JOIN EXW.dbo.EXW_DimUser edu WITH (NOLOCK)ON cb.GCID = edu.GCID
LEFT JOIN EXW.dbo.BalanceKnownGaps bkg WITH (NOLOCK)ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
LEFT JOIN EXW.dbo.EXW_FactBalance efb WITH (NOLOCK) ON cb.WalletId = efb.WalletID  AND cb.CryptoId = efb.CryptoId 
 AND efb.FullDateID =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
WHERE cb.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
-- AND edu.CountryID =143 
 AND cb.CountryID=<[Parameters].[Parameter 1]>
GROUP BY cb.CryptoName
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END 
, cb.Regulation
)sub