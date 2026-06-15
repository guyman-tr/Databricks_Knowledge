select 
   e.BalanceDate    FullDate
  ,e.GCID
  ,e.CryptoID CryptoId
  ,e.CryptoName
  ,ct.BlockchainCryptoId
  ,e.Country
  ,e.Regulation
  ,e.ComplianceClosureEvent
  ,e.AMLClosureEvent
  ,CASE 
		WHEN e.IsTestAccount =1 THEN  'TestUser'
		WHEN e.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
,  e.Balance 
,  e.BalanceUSD 
  FROM EXW_dbo.EXW_FinanceReportsBalancesNew e
  JOIN EXW_Wallet.CryptoTypes ct ON e.CryptoID = ct.CryptoID 
  WHERE e.BalanceDateID > CAST(FORMAT(CAST(getdate()-8 AS DATE),'yyyyMMdd') as INT)