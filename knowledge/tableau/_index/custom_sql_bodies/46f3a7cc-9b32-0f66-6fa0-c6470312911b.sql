SELECT * FROM 

(SELECT 
sub.USD
, sub.GCID
,sub.RealCID
,   sub. RealUser
, sub.CountryID
, sub.Country
	, sub.Regulation
  , row_number() over (partition by Country order by sub.USD desc) as country_rank 
FROM 
(



SELECT
 SUM(CASE WHEN bkg.WalletId IS NULL THEN cb.BalanceUSD ELSE efb.BalanceUSD END) USD
, cb.GCID
, cb.RealCID
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, cb.CountryID
	, cb.Country
	, cb.Regulation
FROM  EXW.dbo.EXW_UserCalculatedBalance  cb  WITH (NOLOCK)
JOIN EXW.dbo.EXW_DimUser edu WITH (NOLOCK) ON cb.GCID = edu.GCID
LEFT JOIN EXW.dbo.BalanceKnownGaps bkg WITH (NOLOCK)ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
LEFT JOIN EXW.dbo.EXW_FactBalance efb  WITH (NOLOCK)ON cb.WalletId = efb.WalletID  AND cb.CryptoId = efb.CryptoId 
 AND efb.FullDateID =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
WHERE cb.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
GROUP BY cb.GCID, cb.RealCID
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END 
, cb.CountryID
	, cb.Country	
		, cb.Regulation
	)sub
)a
WHERE  country_rank <=<[Parameters].[Parameter 2]>