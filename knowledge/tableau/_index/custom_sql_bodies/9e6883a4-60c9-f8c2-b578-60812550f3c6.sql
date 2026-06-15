SELECT e.C2FCorrelationID
	  ,e.GCID
	  ,e.RealCID
	  ,e.EstimatedUsdAmount
	  ,e.EstimatedCryptoToUsdRate
	  ,e.EstimatedFiatToUsdRate
	  ,e.C2FConversionID
	  ,e.Crypto
	  ,e.FiatCurrency
	  ,e.CryptoAmount
	  ,e.ConversionDateTime
	  ,e.ConversionStatus
 	  ,e.ConversionStatusDate
	  ,e.EstimatedCryptoToFiatRate
	  ,e.CryptoToFiatRate
	  ,(e.CryptoToFiatRate-e.EstimatedCryptoToFiatRate)/e.EstimatedCryptoToFiatRate  RateSlippage
	  ,e.CryptoAmount*e.EstimatedCryptoToFiatRate/100*TotalFeePercentage  EstimatedFeeFiat
	  ,e.EstimatedFiatAmount
	  ,e.FiatAmount
	   ,e.FiatToUsdRate
	  ,e.CryptoToUsdRate
	  ,e.UsdAmount
	  ,e.eMoneyReferenceNumber
	  ,e.eMoneyProviderTransactionID
	  ,e.ConversionCycle
	  ,e.IsTestAccount
	 ,e.TotalFeePercentage/100 TotalFeePercentage
     , e.eMoneyHolderID HolderID
	 , e.TargetPlatform
FROM EXW_dbo.EXW_C2F_E2E e 
 

WHERE   (e.ConversionDate >= <[Parameters].[Parameter 1]>  or  e.ConversionStatusDate  >= <[Parameters].[Parameter 1]>)
      AND ( e.ConversionDate  < <[Parameters].[Start Date for Report (copy)_223772611717361664]>  OR  e.ConversionStatusDate  < <[Parameters].[Start Date for Report (copy)_223772611717361664]>)