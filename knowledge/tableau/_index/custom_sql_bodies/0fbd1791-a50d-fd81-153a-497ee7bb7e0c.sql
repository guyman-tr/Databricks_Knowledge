SELECT 
	EOMONTH(ecpee.LastModificationDate) as Month
	  --ecpee.TargetPlatform
	  --,ecpee.ConversionCycle
	  --,ecpee.LastModificationDate
	  --,ecpee.GCID
	  --,ecpee.RealCID
	  --,ecpee.RequestTime
	  --,ecpee.RequestLastStatus
	  --,ecpee.WalletRequestType 
	  --,ecpee.SentLastStatus
	  --,ecpee.WalletTransactionType
	  --,ecpee.EstimatedFiatAmount
	  ,sum(ecpee.EstimatedUsdAmount) as USD_Amount
	  ,ecpee.Crypto
	  --,ecpee.FiatCurrency
	  --,ecpee.CryptoAmount
	  --,ecpee.ConversionStatus
	  --,ecpee.PositionID
	  ,count(distinct ecpee.PositionUSD) as TotalPositions
	  --,ecpee.PositionUnits
	  ,ecpee.InstrumentName
	  ,ecpee.Regulation
	  ,ecpee.Country
	  ,ecpee.Club
	  ,ecpee.PlayerStatus
	  ,CASE  WHEN ecpee.IsTestAccount =1 THEN 'Test'
              WHEN dc.IsValidCustomer =0 THEN 'eTorian' 
              WHEN  dc.AccountTypeID IN (7,13) THEN 'eTorian'
			  WHEN  dc.PlayerLevelID =4  THEN 'eTorian'
			  ELSE 'RealUser'
			  END 'UserType'
 FROM 
	EXW_dbo.EXW_C2P_E2E ecpee
 JOIN 
	DWH_dbo.Dim_Customer dc  ON ecpee.GCID = dc.GCID
WHERE   
	YEAR(LastModificationDate) >= '2025' 
	and ecpee.ConversionStatus = 'Completed'
GROUP BY 
		EOMONTH(ecpee.LastModificationDate)
		,ecpee.Crypto
		,ecpee.InstrumentName
		,ecpee.Regulation
		,ecpee.Country
		,ecpee.Club
		,ecpee.PlayerStatus
		,CASE  WHEN ecpee.IsTestAccount =1 THEN 'Test'
              WHEN dc.IsValidCustomer =0 THEN 'eTorian' 
              WHEN  dc.AccountTypeID IN (7,13) THEN 'eTorian'
			  WHEN  dc.PlayerLevelID =4  THEN 'eTorian'
			  ELSE 'RealUser'
		END