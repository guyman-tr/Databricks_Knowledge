SELECT
    CAST(ecfee.RealCID AS INT) CID
	,ecfee.GCID
  -- ,ecfee.C2FCorrelationID
  -- ,ecfee.TargetPlatformID
   --,ecfee.TargetPlatform
   --,ecfee.ConversionCycle
   ,ecfee.LastModificationDateTime
   ,ecfee.LastModificationDate
   ,ecfee.LastModificationDateID
   
  --  ,ecfee.RequestID
   --,ecfee.RequestCryptoID
  -- ,ecfee.RequestDateTime
   --,ecfee.RequestLastStatusID
  -- ,ecfee.RequestLastStatus
   ,ecfee.RequestLastStatusDateTime
    ,ecfee.C2FConversionID
   ,ecfee.CryptoID
   ,ecfee.Crypto
   ,ecfee.FiatCurrencyID
   ,ecfee.FiatCurrency
   ,ecfee.CryptoAmount
   ,ecfee.TotalFeePercentage
   ,ecfee.TotalFeeUSD
   ,ecfee.ConversionDateTime
   ,ecfee.ConversionDateID
   ,ecfee.ConversionDate
   ,ecfee.ConversionStatusID
   ,ecfee.ConversionStatus
   ,ecfee.ConversionStatusDateTime
   ,ecfee.ConversionStatusDateID
   ,ecfee.ConversionStatusDate
   ,ecfee.BlockchainTransactionID
   ,ecfee.FromAddress
   ,ecfee.ToAddress
   ,ecfee.BlockchainFee
   ,ecfee.CryptoTransactionDateTime
   ,ecfee.CryptoTransactionDateID
   ,ecfee.CryptoTransactionDate
   ,ecfee.CryptoToFiatRate
   ,ecfee.FiatToUsdRate
   ,ecfee.CryptoToUsdRate
   ,ecfee.FiatAmount
   ,ecfee.UsdAmount
   ,ecfee.FiatAccountID
   ,ecfee.FiatDetails
   ,ecfee.RateTime
   ,ecfee.FiatTxTime
   ,ecfee.IsRequestDone
   ,ecfee.TribeHolderAmount
   ,ecfee.TribeTxDateTime
   ,ecfee.RegulationID
   ,ecfee.Regulation
   ,ecfee.CountryID
   ,ecfee.Country
   ,ecfee.CustomerRegionID
   ,ecfee.State
   ,ecfee.IsValidCustomer
   ,ecfee.IsCreditReportValidCB
   ,ecfee.PlayerLevelID
   ,ecfee.Club
   ,ecfee.PlayerStatusID
   ,ecfee.PlayerStatus
   ,ecfee.WalletEntity
   ,ecfee.AccountManager
    FROM EXW_dbo.EXW_C2F_E2E ecfee
 WHERE   1=1
 AND ecfee.TargetPlatformID =1
AND ecfee.ConversionCycle ='Full Cycle'
 AND   LastModificationDate>=  <[Parameters].[Parameter 1]>
 AND    LastModificationDate <= <[Parameters].[Start Date for Report (copy)_223772611717361664]>