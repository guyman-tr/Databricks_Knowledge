SELECT ecfr.C2FCorrelationID
	  ,ecfr.GCID
	  ,ecfr.RealCID
	  ,ecfr.C2FConversionID
	  ,ecfr.CryptoID
	  ,ecfr.Crypto
	  ,ecfr.FiatCurrencyID
	  ,ecfr.FiatCurrency
	  ,ecfr.CryptoAmount
	  ,ecfr.TotalFeePercentage
		  ,ecfr.TotalFeeUSD
	 ,ecfr.ConversionDate
	 ,ecfr.CryptoTransactionDate AS [C2F Date]
	  ,ecfr.ConversionStatusID
	  ,ecfr.ConversionStatus  [C2F Status]
	 ,ecfr.ConversionStatusDate  [C2F Status Date]
      ,ecfr.FiatAmount
	  ,ecfr.UsdAmount
	  ,ecfr.eMoneyIsValidETM
	  ,ecfr.Club
	  ,ecfr.Regulation
	  ,ecfr.Country
      ,ecfr.eMoneyHolderAmount
 
	   ,ecfr.ConversionCycle 
	  ,ecfr.IsTestAccount
,TargetPlatform
,WalletEntity
		 FROM EXW_dbo.EXW_C2F_E2E ecfr