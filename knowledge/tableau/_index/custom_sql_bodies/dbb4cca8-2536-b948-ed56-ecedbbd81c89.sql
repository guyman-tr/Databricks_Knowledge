-- crypto-to-fiat
SELECT 
	  ecfee.IsTestAccount
	  ,ecfee.LastModificationDate
	  ,ecfee.BlockchainTransactionID
	  ,ecfee.GCID
	  ,ecfee.RealCID
	  ,ecfee.RequestID
	  ,ecfee.RequestDateTime 
	  ,ecfee.SentTransactionDateTime
	  ,ecfee.Crypto
	  ,ecfee.SentAmount AS CryptoAmountInUnits--crypto position value in unit (same as CryptoAmount)
	  ,ecfee.CryptoToFiatRate
	  ,ecfee.SentAmount * ecfee.CryptoToFiatRate AS CryptoAmountUSDinWallet
	  --,ecfee.CryptoToFiatRate,ecfee.TotalFeePercentage
	  ,ecfee.TotalFeeUSD
	  ,ecfee.DepositID
	  ,ecfee.DepositModificationTime
	  ,ecfee.DepositUSD --candidate for fiat deposited into TP as cash (same as UsdAmount)
	  ,ecfee.RegulationID
	  ,ecfee.Regulation
	  ,ecfee.CountryID
	  ,ecfee.Country
	  ,ecfee.State
	  ,ecfee.PlayerStatus
	  ,ecfee.WalletEntity
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ecfee
 WHERE   
    LastModificationDate >=  DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)
	AND ecfee.RegulationID IN (6,7,8,12,14)
	AND ecfee.TargetPlatformID=2
	AND ecfee.IsValidCustomer=1
	AND ecfee.DepositModificationTime is NOT NULL