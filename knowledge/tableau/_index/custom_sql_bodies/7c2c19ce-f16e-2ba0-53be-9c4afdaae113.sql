SELECT 
a.RealUser
, a.Regulation
, a.UniqueUsers as 'Unique Users'
, a.WalletsNumber as 'Wallets Number'
, b.[Total Users ON Balance]
, b.[Total Assets USD]
, b.[Customer with Zero Balance]
, b.[Customer with >0 Balance]
, b.[Customer with Balance above 0 and less than 50$]
, b.[Customer with Balance above 50$ AND less than 100$]
, b.[Customer with Balance above 100$ AND  less than 1k$]
, b.[Customer with Balance above 1k $ and less than 3K]
, b.[Customer with Balance above 3k $ and less than 5K]
, b.[Customer with Balance above 5k $ and less than 10k$]
, b.[Customer with Balance above 10k $ and less than 25K $]
, b.[Customer with Balance between 25k $ and 50k $]
FROM 

(SELECT
  COUNT(DISTINCT ewi.GCID) UniqueUsers
, COUNT(ewi.WalletID) WalletsNumber 
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, edu.Regulation
FROM EXW.dbo.EXW_WalletInventory ewi WITH (NOLOCK)
JOIN EXW.dbo.EXW_DimUser edu WITH (NOLOCK) ON ewi.GCID = edu.GCID
WHERE 1=1 
 --AND edu.IsTestAccount =0 
--AND edu.CountryID =164
AND edu.CountryID = <[Parameters].[Parameter 1]>
GROUP BY 
CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END
	,edu.Regulation
)a

CROSS APPLY 
(
SELECT 
Count (s.GCID) 'Total Users ON Balance'
, SUM(s.USD) 'Total Assets USD'
,Sum (CASE WHEN s.USD>0 THEN 1 ELSE 0 END) 'Customer with >0 Balance'
  ,Sum(CASE WHEN s.USD=0 THEN 1 ELSE 0 END) 'Customer with Zero Balance'
 -- , Sum(CASE WHEN s.USD>2 THEN 1 ELSE 0 END) 'Customer with Balance above 2 $'
    , Sum(CASE WHEN s.USD>0 AND  s.USD < 50 THEN 1 ELSE 0 END) 'Customer with Balance above 0 and less than 50$'
	    , Sum(CASE WHEN s.USD>50 AND  s.USD < 100 THEN 1 ELSE 0 END) 'Customer with Balance above 50$ AND less than 100$'
		  , Sum(CASE WHEN s.USD>100 AND  s.USD < 1000 THEN 1 ELSE 0 END) 'Customer with Balance above 100$ AND  less than 1k$'
		  	  , Sum(CASE WHEN s.USD>1000  AND s.USD<3000 THEN 1 ELSE 0 END) 'Customer with Balance above 1k $ and less than 3K'
	  , Sum(CASE WHEN s.USD>3000  AND s.USD<5000 THEN 1 ELSE 0 END) 'Customer with Balance above 3k $ and less than 5K'
	  	  , Sum(CASE WHEN s.USD>5000 AND s.USD<10000 THEN 1 ELSE 0 END) 'Customer with Balance above 5k $ and less than 10k$'
		   , Sum(CASE WHEN s.USD>10000 AND s.USD < 25000THEN 1 ELSE 0 END) 'Customer with Balance above 10k $ and less than 25K $'
		   	   , Sum(CASE WHEN s.USD>=25000 AND s.USD <=50000 THEN 1 ELSE 0 END) 'Customer with Balance between 25k $ and 50k $'
			   	, s.RealUser	
				, s.Regulation
FROM 
(

SELECT
 SUM(CASE WHEN bkg.WalletId IS NULL THEN cb.BalanceUSD ELSE efb.BalanceUSD END) USD
, cb.GCID
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	, edu.Regulation
FROM  EXW.dbo.EXW_UserCalculatedBalance  cb  WITH (NOLOCK)
JOIN EXW.dbo.EXW_DimUser edu ON cb.GCID = edu.GCID
LEFT JOIN EXW.dbo.BalanceKnownGaps bkg WITH (NOLOCK)ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
LEFT JOIN EXW.dbo.EXW_FactBalance efb  WITH (NOLOCK)ON cb.WalletId = efb.WalletID 
 AND cb.CryptoId = efb.CryptoId 
 AND efb.FullDateID =CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)
WHERE cb.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
--AND cb.IsTestAccount =0 
--AND edu.CountryID =164 
AND cb.CountryID=<[Parameters].[Parameter 1]> 
GROUP BY cb.GCID
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END
	, edu.Regulation
)s
GROUP BY s.RealUser , s.Regulation ) b
WHERE a.RealUser=b.RealUser AND 	a.Regulation=b.Regulation