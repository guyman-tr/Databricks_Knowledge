SELECT DISTINCT 
	  hob.ReportDate
	, hob.WalletID
	, hob.CryptoID
	, hob.InstrumentID
	, hob.Balance
	, hob.WalletType
	, hob.BalanceDate
	, edct.Name AS CryptoName
	, eiw.Address
FROM EXW_dbo.Hourly_OmnibusBalances hob
JOIN EXW_Wallet.CryptoTypes edct
	ON hob.CryptoID = edct.CryptoID
LEFT JOIN EXW_dbo.EXW_InternalWallet eiw
	ON hob.WalletID = eiw.Id