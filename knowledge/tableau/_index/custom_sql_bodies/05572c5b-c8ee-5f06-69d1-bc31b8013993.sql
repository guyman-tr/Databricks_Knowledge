SELECT
	fb.BalanceDate     FullDate
   ,fb.BalanceDateID    FullDateID
   ,fb.GCID
   ,fb.RealCID
   --,fb.Username
   --,fb.FirstName
   --,fb.LastName
   ,ect.BlockchainCryptoId  
   ,ect2.Name AS BlockchainCryptoName
   ,fb.WalletID
   ,fb.Balance
   ,fb.BalanceUSD
   ,fb.UpdateDate
   ,fb.CryptoID AS CryptoIdERC
   ,fb.CryptoName AS CryptoNameERC
   ,du.Region
   ,CASE
		--WHEN fb.GCID <= 0 THEN 'Omnibus'
		WHEN du.IsTestAccount = 1 THEN 'TestAccount'
		WHEN du.CreditReportValid = 0 OR
			du.CountryID = 250 OR dc.PlayerLevelID =4 THEN  'eTorian'
		--WHEN dc.GCID <= 0 THEN 'Omnibus'
		ELSE 'RealUser'
	END AS IsRealUser
   ,ps.Name AS PlayerStatus
   ,das.AccountStatusName AS AccountStatus
   ,dr.Name AS Regulation
   ,sp.ShortName AS StateCode
   ,sp.Name AS State
, fb.Country
FROM EXW_dbo.EXW_FinanceReportsBalancesNew fb
JOIN EXW_dbo.EXW_DimUser du
	ON fb.RealCID = du.RealCID
JOIN DWH_dbo.Dim_Customer dc
	ON fb.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_PlayerStatus ps
	ON dc.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_AccountStatus das
	ON dc.AccountStatusID = das.AccountStatusID
LEFT JOIN DWH_dbo.Dim_State_and_Province sp
	ON dc.RegionID = sp.RegionByIP_ID
JOIN DWH_dbo.Dim_Regulation dr
	ON dc.RegulationID = dr.DWHRegulationID
JOIN EXW_Wallet.CryptoTypes ect  
	ON fb.CryptoID = ect.CryptoID
LEFT JOIN EXW_Wallet.CryptoTypes ect2  
	ON ect.BlockchainCryptoId =ect2.CryptoID

WHERE fb.BalanceDate = CAST(GETDATE()-2 AS DATE)