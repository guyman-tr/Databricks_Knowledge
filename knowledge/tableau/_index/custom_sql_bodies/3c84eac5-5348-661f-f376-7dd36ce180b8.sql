SELECT efrbn.GCID
	  ,efrbn.RealCID
	,efrbn.WalletID
	 -- ,efrbn.PublicAddress
	 -- ,efrbn.CryptoID
	  ,efrbn.CryptoName
	  ,efrbn.BalanceDate
	  ,efrbn.BalanceDateID
	  ,efrbn.Balance
	  ,efrbn.BalanceUSD
	--  ,efrbn.RegulationID
	  ,efrbn.Regulation
	--  ,efrbn.CountryID
	  ,efrbn.Country
	  ,efrbn.IsTestAccount
	  ,efrbn.IsValidCustomer
	  ,efrbn.VerificationLevelID
	--  ,efrbn.PlayerLevelID
	  ,efrbn.Club
	  ,efrbn.ComplianceClosureEvent
	  ,efrbn.AMLClosureEvent
	  ,efrbn.UserWalletAllowance
	  --,efrbn.UpdateDate 
	  ,CASE WHEN  DisplayName   LIKE  'eToro%' THEN 1 ELSE 0 END 'XToken'
	  ,efrbn.WalletEntity
	  FROM EXW_dbo.EXW_FinanceReportsBalancesNew efrbn 
	  JOIN EXW_Wallet.CryptoTypes  ect  ON efrbn.CryptoID =ect.CryptoID 
	  LEFT JOIN  EXW_dbo.EXW_DimUser_Enriched edue ON efrbn.GCID = edue.GCID
	 --- LEFT JOIN EXW_dbo.EXW_WalletRegulation  wr ON efrbn.GCID = wr.GCID AND BalanceDateID  BETWEEN wr.FromDateID AND wr.ToDateID
  WHERE efrbn.BalanceDateID >=CAST(FORMAT(CAST(getdate()-<[Parameters].[Top X Countries by USD (copy)]> AS DATE),'yyyyMMdd') as INT)