SELECT ecfr.C2FCorrelationID
	  ,ecfr.GCID
	  ,ecfr.RealCID
	  --,ecfr.RequestID
	  --,ecfr.RequestCryptoID
	  --,ecfr.RequestTimestamp
	  --,ecfr.RequestLastStatusID
	  --,ecfr.RequestLastStatus
	  --,ecfr.RequestStatusTimestamp
	  --,ecfr.SentTransactionID
	  --,ecfr.SentBlockchainTransactionID
	  --,ecfr.SentWalletID
	  --,ecfr.SentTransactionOccurred
	  --,ecfr.SentBlockchainFee
	  --,ecfr.SentCryptoID
	  --,ecfr.SentToAddress
	  --,ecfr.SentAmount
	  --,ecfr.SentEtoroFees
	  --,ecfr.SentLastStatusID
	  --,ecfr.SentLastStatus
	  --,ecfr.EstimatedFiatAmount
	  --,ecfr.EstimatedUsdAmount
	  --,ecfr.EstimatedCryptoToUsdRate
	  --,ecfr.EstimatedFiatToUsdRate
	  --,ecfr.EstimatedCryptoToFiatRate
	  --,ecfr.EstimatedDateTime
	   ,ecfr.C2FConversionID
	  --,ecfr.TargetPlatformID
	  --,ecfr.TargetPlatform
	  ,ecfr.CryptoID
	  ,ecfr.Crypto
	  ,ecfr.FiatCurrencyID
	  ,ecfr.FiatCurrency
	  ,ecfr.CryptoAmount
	  ,ecfr.TotalFeePercentage
	  ,ecfr.ConversionFeePercentage
	  ,ecfr.ServiceFeePercentage
	  ,ecfr.TotalFeeUSD
	  ,ecfr.ConversionFeeUSD
	  ,ecfr.ServiceFeeUSD
	--  ,ecfr.ConversionDateTime
	 -- ,ecfr.ConversionDateID
	  ,ecfr.ConversionDate
	--  ,ecfr.BlockchainTransactionID
	--  ,ecfr.ToAddress
	--  ,ecfr.BlockchainFee
	 -- ,ecfr.CryptoTransactionDateTime
--	  ,ecfr.CryptoTransactionDateID
	  ,ecfr.CryptoTransactionDate AS [C2F Date]
	  ,ecfr.ConversionStatusID
	  ,ecfr.ConversionStatus  [C2F Status]
	--  ,ecfr.ConversionStatusDateTime
	 -- ,ecfr.ConversionStatusDateID
	  ,ecfr.ConversionStatusDate  [C2F Status Date]
	--  ,ecfr.CryptoToFiatRate
	--  ,ecfr.FiatToUsdRate
	 -- ,ecfr.CryptoToUsdRate
	  ,ecfr.FiatAmount
	  ,ecfr.UsdAmount
	 -- ,ecfr.FiatAccountID
	 -- ,ecfr.FiatDetails
	 -- ,ecfr.RateTime
	--  ,ecfr.FiatTxTime
	 -- ,ecfr.eMoneyTransactionID
	--  ,ecfr.eMoneyAccountID
	--  ,ecfr.eMoneyCardID
	--  ,ecfr.eMoneyProviderCardID
	--  ,ecfr.eMoneyCurrencyBalanceID
	--  ,ecfr.eMoneyProviderCurrencyBalanceID
	--  ,ecfr.eMoneyTxType
	--  ,ecfr.eMoneyTxCreatedDate
	--  ,ecfr.eMoneyTxLocalTime
	--  ,ecfr.eMoneyReferenceNumber
	--  ,ecfr.eMoneyProviderTransactionID
	--  ,ecfr.eMoneyAccountProgram
	 -- ,ecfr.eMoneyAccountSubProgram
	  ,ecfr.eMoneyIsValidETM
	--  ,ecfr.eMoneyIsValidCustomer
	  ,ecfr.eMoneyClubTxDate  Club
	--  ,ecfr.eMoneyRegulationIDTxDate
	  ,ecfr.eMoneyRegulationTxDate  Regulation
	--  ,ecfr.eMoneyCountryIDTxDate
	  ,ecfr.eMoneyCountryTxDate Country
	  --,ecfr.eMoneyPlayerStatusIDTxDate
	 -- ,ecfr.eMoneyPlayerStatusTxDate
	 -- ,ecfr.eMoneyLastTxStatusID
	  ,ecfr.eMoneyLastTxStatus
	--  ,ecfr.eMoneyAuthorizationTypeID
	  ,ecfr.eMoneyAuthorizationType
	 -- ,ecfr.eMoneyHolderCurrencyISO
	  ,ecfr.eMoneyHolderCurrencyDesc
	  ,ecfr.eMoneyHolderAmount
	  ,ecfr.eMoneyAccumulatedAmount
	--  ,ecfr.eMoneyLastStatusTime
	  ,ecfr.eMoneyLastStatusDate  [eMoney Status Date]
	  ,ecfr.ConversionCycle 
	--  ,ecfr.FromAddress
	  ,ecfr.IsTestAccount
	--  ,ecfr.IsRequestDone
	--  ,ecfr.UpdateDate
	  FROM EXW_dbo.EXW_C2F_E2E ecfr