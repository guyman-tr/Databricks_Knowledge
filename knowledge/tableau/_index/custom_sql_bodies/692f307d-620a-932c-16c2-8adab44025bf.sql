SELECT a.DateID
	 , a.CID
	 , a.DepositWithdrawID
	 , a.Occurred
	 , a.CreditTypeID
	 , a.TransactionID
	 , a.Date
	 , a.Customer
	 , a.TransactionType
	 , a.PaymentMethod
	 , a.Amount
	 , a.Currency
	 , a.ExchangeRate
	 , a.AmountUSD
	 , a.RegulationID
	 , a.LabelID
	 , a.PlayerLevelID
	 , a.Regulation
	 , a.[Label]
	 , a.IsValidCustomer
	 , a.UpdateDate
	 , a.BaseExchangeRate
	 , a.ExchangeFee
	 , a.ExternalTransactionID
	 , a.Depot
	 , CASE when a.MIDValue IS NULL THEN a.MID2 ELSE a.MIDValue END AS MIDValue
	 , a.Club
	 , a.PlayerStatus
	 , a.PIPsCalculation
	 , a.RegCountry
	 , a.RegCountryByIP
	 , a.CardType
	 , a.CardCategory
	 , a.BinCountry
	 , a.MOPCountry
	 , a.IsGermanBaFin
	 , CASE WHEN a.Entity IS NULL THEN a.Entity2 ELSE a.Entity END AS Entity
	 , a.RN 
	 , a.Entity2
	 , a.MID2
FROM 
(
select  
	 bddwf.DateID
	 , CID
	 , DepositWithdrawID
	 , Occurred
	 , CreditTypeID
	 , REPLACE(REPLACE (bddwf.TransactionID, 'D', ''), 'W', '') AS TransactionID
	 , bddwf.Date
	 , Customer
	 , TransactionType
	 , PaymentMethod
	 , Amount
	 , Currency
	 , ExchangeRate
	 , AmountUSD
	 , RegulationID
	 , LabelID
	 , PlayerLevelID
	 , Regulation
	 , [Label]
	 , IsValidCustomer
	 , bddwf.UpdateDate
	 , BaseExchangeRate
	 , ExchangeFee
	 , ExternalTransactionID
	 , Depot
	 , bdprms.MID as MIDValue
	 , Club
	 , PlayerStatus
	 , PIPsCalculation
	 , RegCountry
	 , RegCountryByIP
	 , CardType
	 , CardCategory
	 , BinCountry
	 , MOPCountry
	 , IsGermanBaFin
	 , bdprms.MIDName AS Entity
	 , ROW_NUMBER () OVER (PARTITION BY bddwf.TransactionID, TransactionType ORDER BY Occurred, MIDValue desc) AS RN
	 , CASE WHEN PaymentMethod LIKE '%Crypto%' THEN '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'eToroME'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'BHDUSD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'BRL' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'BRL' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CHF' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CHF' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'CLP' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'CLP' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CZK' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'DKK' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'HUF' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'KRW' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'NOK' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'PENUSD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'PENUSD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'PLN' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'QARUSD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'SEK' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroUS'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroAU'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'eToroME'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USDRON' and Depot = 'Checkout' then 'eToroEU'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'EtoroOptions' and Currency = 'USD' and Depot = 'EtoroOptions' then 'eToroUS'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'IXOPAY-Nuvei' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'IXOPAY-Nuvei' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'IXOPAY-Nuvei' then 'EMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'IXOPAY-Nuvei' then 'eToroUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'EMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'EMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'iDEAL' and Currency = 'EUR' and Depot = 'IXOPAY-Worldpay' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'Przelewy24' and Currency = 'PLN' and Depot = 'IXOPAY-Worldpay-P24' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'MoneyBookers' and Currency = 'EUR' and Depot = 'MoneyBookers USD' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'MoneyBookers' and Currency = 'USD' and Depot = 'MoneyBookers USD' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDIDR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDIDR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSRA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDTHB' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDVND' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDVND' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'eToroMoney' and Currency = 'EUR' and Depot = 'Tribe' then 'eToroEU'
			when Regulation = 'FCA' and PaymentMethod = 'eToroMoney' and Currency = 'EUR' and Depot = 'Tribe' then 'eToroEU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroUK'
			when Regulation = 'FCA' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'WorldPay' then '0'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'eToroEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'WorldPay' then 'eToroUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroUK'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroUS'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroUK'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'eToroAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = '' and Currency = '' and Depot = '' then 'eToroAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = '' and Currency = '' and Depot = '' then 'EMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = '' and Currency = '' and Depot = '' then 'eToroAU'
	   ELSE 'NA' END AS Entity2
	   , CASE WHEN PaymentMethod LIKE '%Crypto%' THEN '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'AEDUSD' and Depot = 'Checkout' then 'CheckoutME'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'BHDUSD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'BRL' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'BRL' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CHF' and Depot = 'Checkout' then 'CheckoutEUROW'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CHF' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'CLP' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'CLP' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'CZK' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'DKK' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'CheckoutEUROW'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'Checkout' then 'CheckoutUKEEA'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'CheckoutUKEEA'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'HUF' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'KRW' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'MXN' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'NOK' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'OMRUSD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'PENUSD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'PENUSD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'PLN' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'QARUSD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'SEK' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'SGD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutEUROW'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutUKEEA'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutUS'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutUKROW'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutME'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'Checkout' then 'CheckoutAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USDRON' and Depot = 'Checkout' then 'CheckoutEUEEA'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'EtoroOptions' and Currency = 'USD' and Depot = 'EtoroOptions' then 'eToroOptionsUS'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'IXOPAY-Nuvei' then 'NuveiAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'IXOPAY-Nuvei' then 'NuveiEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'IXOPAY-Nuvei' then 'NuveiEMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'IXOPAY-Nuvei' then 'NuveiUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'NuveiAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'NuveiEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'NuveiEMUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'NuveiUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'IXOPAY-Nuvei' then 'NuveiEMUK'
			when Regulation = 'CySEC' and PaymentMethod = 'iDEAL' and Currency = 'EUR' and Depot = 'IXOPAY-Worldpay' then 'iDEALEU'
			when Regulation = 'CySEC' and PaymentMethod = 'Przelewy24' and Currency = 'PLN' and Depot = 'IXOPAY-Worldpay-P24' then 'Przelewy24EU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'MoneyBookers' and Currency = 'EUR' and Depot = 'MoneyBookers USD' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'MoneyBookers' and Currency = 'USD' and Depot = 'MoneyBookers USD' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDIDR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDIDR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDMYR' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSRA' and PaymentMethod = 'OnlineBanking' and Currency = 'USDPHP' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDTHB' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'OnlineBanking' and Currency = 'USDVND' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'OnlineBanking' and Currency = 'USDVND' and Depot = 'OnlineBanking(Zotapay)' then '0'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FCA' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'PayPal' and Currency = 'USD' and Depot = 'PayPal' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'eToroMoney' and Currency = 'EUR' and Depot = 'Tribe' then 'eToroMoneyEU'
			when Regulation = 'FCA' and PaymentMethod = 'eToroMoney' and Currency = 'EUR' and Depot = 'Tribe' then 'eToroMoneyEU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroMoneyUK'
			when Regulation = 'FCA' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroMoneyUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'eToroMoney' and Currency = 'GBP' and Depot = 'Tribe' then 'eToroMoneyUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'AUD' and Depot = 'WorldPay' then '0'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'WorldpayEU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'EUR' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'ASIC' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'GBP' and Depot = 'WorldPay' then 'WorldpayUK'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then '0'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayEU'
			when Regulation = 'CySEC' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayUK'
			when Regulation = 'FCA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayUK'
			when Regulation = 'FinCEN+FINRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayUS'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayUK'
			when Regulation = 'FSRA' and PaymentMethod = 'CreditCard' and Currency = 'USD' and Depot = 'WorldPay' then 'WorldpayAU'
			when Regulation = 'ASIC & GAML' and PaymentMethod = '' and Currency = '' and Depot = '' then 'WorldpayAU'
			when Regulation = 'FSA Seychelles' and PaymentMethod = '' and Currency = '' and Depot = '' then 'CheckoutEMUK'
			when Regulation = 'FSA Seychelles' and PaymentMethod = '' and Currency = '' and Depot = '' then 'CheckoutAU'
	   ELSE 'NA' END AS MID2
from BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf with (nolock)
left join BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings bdprms
	ON bddwf.Date = bdprms.Date 
		AND bddwf.TransactionID = bdprms.TransactionID 
where bddwf.Date between <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>
) a
WHERE a.RN = 1
UNION ALL
SELECT bdwrp.DateID
	 , bdwrp.CID
	 , bdwrp.DepositWithdrawID
	 , bdwrp.Occurred
	 , bdwrp.CreditTypeID
	 , REPLACE(REPLACE (TransactionID, 'D', ''), 'W', '') AS TransactionID
	 , bdwrp.Date
	 , bdwrp.Customer
	 , bdwrp.TransactionType
	 , bdwrp.PaymentMethod
	 , bdwrp.Amount
	 , bdwrp.Currency
	 , bdwrp.ExchangeRate
	 , bdwrp.AmountUSD
	 , bdwrp.RegulationID
	 , bdwrp.LabelID
	 , bdwrp.PlayerLevelID
	 , bdwrp.Regulation
	 , bdwrp.[Label]
	 , bdwrp.IsValidCustomer
	 , bdwrp.UpdateDate
	 , bdwrp.BaseExchangeRate
	 , bdwrp.ExchangeFee
	 , bdwrp.ExternalTransactionID
	 , bdwrp.Depot
	 , bdwrp.MIDValue
	 , bdwrp.Club
	 , bdwrp.PlayerStatus
	 , bdwrp.PIPsCalculation
	 , bdwrp.RegCountry
	 , bdwrp.RegCountryByIP
	 , bdwrp.CardType
	 , bdwrp.CardCategory
	 , bdwrp.BinCountry
	 , bdwrp.MOPCountry
	 , bdwrp.IsGermanBaFin
	 , bdwrp.Entity
	 , NULL AS RN
	 , 'NA' AS Entity2
	 , 'NA' AS MID2
FROM BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs bdwrp
WHERE Date BETWEEN <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>
--AND TransactionID = '12486118W'
UNION ALL
SELECT *
FROM 
(
SELECT bddrp.DateID
	 , bddrp.CID
	 , bddrp.DepositWithdrawID
	 , bddrp.Occurred
	 , bddrp.CreditTypeID
	 , REPLACE(REPLACE (TransactionID, 'D', ''), 'W', '') AS TransactionID
	 , bddrp.Date
	 , bddrp.Customer
	 , bddrp.TransactionType
	 , bddrp.PaymentMethod
	 , bddrp.Amount
	 , bddrp.Currency
	 , bddrp.ExchangeRate
	 , bddrp.AmountUSD
	 , bddrp.RegulationID
	 , bddrp.LabelID
	 , bddrp.PlayerLevelID
	 , bddrp.Regulation
	 , bddrp.[Label]
	 , bddrp.IsValidCustomer
	 , bddrp.UpdateDate
	 , bddrp.BaseExchangeRate
	 , bddrp.ExchangeFee
	 , bddrp.ExternalTransactionID
	 , bddrp.Depot
	 , bddrp.MIDValue
	 , bddrp.Club
	 , bddrp.PlayerStatus
	 , bddrp.PIPsCalculation
	 , bddrp.RegCountry
	 , bddrp.RegCountryByIP
	 , bddrp.CardType
	 , bddrp.CardCategory
	 , bddrp.BinCountry
	 , bddrp.MOPCountry
	 , bddrp.IsGermanBaFin
	 , bddrp.Entity	
	 , ROW_NUMBER () OVER (PARTITION BY TransactionID, TransactionType ORDER BY Occurred, MIDValue desc) AS RN
	 , 'NA' AS Entity2
	 , 'NA' AS MID2
FROM BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs bddrp 
WHERE Date BETWEEN <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>
) b
WHERE b.RN = 1