--weekly
SELECT 
  SUM (fb.BalanceUSD) as USD
 ,SUM(fb.Balance) AS Units
, fb.BalanceDate AS FullDate
, fb.Club
, fb.Country
--, dc.Region
, fb.Regulation
, fb.CryptoName
, fb.CryptoID
, fb.ComplianceClosureEvent
, fb.AMLClosureEvent 
,CASE WHEN  ect.CryptoID = ect.BlockchainCryptoId THEN  'Main Crypto' ELSE  'ERC20' END 'Crypto Type'
,CASE
		WHEN 
			fb.IsTestAccount=1 THEN  'TestUser'
		WHEN fb.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
FROM EXW_dbo.EXW_FinanceReportsBalancesNew fb  WITH (NOLOcK)
JOIN EXW_Wallet.CryptoTypes ect  ON fb.CryptoID = ect.CryptoID
JOIN DWH_dbo.Dim_Date dd on   fb.BalanceDateID = dd.DateKey
WHERE  fb.GCID>0
AND  fb.BalanceDateID>= CAST(FORMAT(CAST(getdate()-70 AS DATE),'yyyyMMdd') as INT) 
AND ( dd.DayNumberOfWeek_Sun_Start=7 OR  fb.BalanceDateID= CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) )--only saturdays or today

GROUP BY 
  fb.BalanceDate  
, fb.Club
, fb.Country
--, dc.Region
, fb.Regulation
, fb.CryptoName
, fb.CryptoID
,CASE WHEN  ect.CryptoID = ect.BlockchainCryptoId THEN  'Main Crypto' ELSE  'ERC20' END 
,CASE
		WHEN 
			fb.IsTestAccount=1 THEN  'TestUser'
		WHEN fb.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END
, fb.ComplianceClosureEvent
, fb.AMLClosureEvent