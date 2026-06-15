SELECT ecpee.CorrelationID
	  ,ecpee.ConversionID
	  ,ecpee.TargetPlatformID
	  ,ecpee.TargetPlatform
	  ,ecpee.ConversionCycle
	  ,ecpee.LastModificationTime
	  ,ecpee.LastModificationDate
	  ,ecpee.LastModificationDateID
	  ,ecpee.GCID
	  ,ecpee.RealCID
	  ,ecpee.RequestID
	  ,ecpee.RequestTime
	  ,ecpee.RequestLastStatusID
	  ,ecpee.RequestLastStatus
	  ,ecpee.RequestLastStatusTime
	  ,ecpee.WalletRequestType
	  ,ecpee.SentTransactionID
	  ,ecpee.SentWalletID
	  ,ecpee.SentTransactionTime
	  ,ecpee.SentBlockchainFee
	  ,ecpee.FromAddress
	  ,ecpee.ToAddress
	  ,ecpee.BlockchainTransactionID
	  ,ecpee.BlockchainFee
	  ,ecpee.SentAmount
	  ,ecpee.SentLastStatusID
	  ,ecpee.SentLastStatus
	  ,ecpee.SentLastStatusTime
	  ,ecpee.WalletTransactionType
	  ,ecpee.EstimatedFiatAmount
	  ,ecpee.EstimatedUsdAmount
	  ,ecpee.EstimatedCryptoToUsdRate
	  ,ecpee.EstimatedFiatToUsdRate
	  ,ecpee.EstimatedCryptoToFiatRate
	  ,ecpee.EstimatedTime
	  ,ecpee.CryptoID
	  ,ecpee.Crypto
	  ,ecpee.FiatCurrencyID
	  ,ecpee.FiatCurrency
	  ,ecpee.CryptoAmount
	  ,ecpee.TotalFeePercentage
	  ,ecpee.TotalFeeUSD
	  ,ecpee.ConversionTime
	  ,ecpee.CryptoTransactionTime
	  ,ecpee.ConversionStatusID
	  ,ecpee.ConversionStatus
	  ,ecpee.ConversionStatusTime
	  ,ecpee.PositionID
	  ,ecpee.AdminLogAmountUnits
	  ,ecpee.HedgeServerID
	  ,ecpee.AdminLogRequestOccurred
	  ,ecpee.AdminLogExecutionOccurred
	  ,ecpee.AdminLogRate
	  ,ecpee.AdminLogRateTime
	  ,ecpee.CompensationCreditID
	  ,ecpee.PositionUSD
	  ,ecpee.PositionUnits
	  ,ecpee.PositionOpenTime
	  ,ecpee.InstrumentID
	  ,ecpee.InstrumentName
	  ,ecpee.CompensationReasonID
	  ,ecpee.CompensationReason
	  ,ecpee.FactActionCompensationOccurred
	  ,ecpee.FactActionCompensationAmountUSD
	  ,ecpee.FactActionPositionOpenOccurred
	  ,ecpee.FactActionPositionOpenAmountUSD
	  ,ecpee.FactActionPositionOpenInitialUnits
	  ,ecpee.IsAirDrop
	  ,ecpee.Commission
	  ,ecpee.FullCommission
	  ,ecpee.IsTestAccount
	  ,ecpee.RegulationID
	  ,ecpee.Regulation
	  ,ecpee.CountryID
	  ,ecpee.Country
	  ,ecpee.CustomerRegionID
	  ,ecpee.State
	  ,ecpee.IsValidCustomer
	  ,ecpee.IsCreditReportValidCB
	  ,ecpee.PlayerLevelID
	  ,ecpee.Club
	  ,ecpee.PlayerStatusID
	  ,ecpee.PlayerStatus
	  ,ecpee.WalletEntity
	  ,ecpee.AccountManager
	  ,ecpee.LabelID
	  ,ecpee.Lable
	  ,ecpee.UpdateDate 
          ,CASE  WHEN ecpee.IsTestAccount =1 THEN 'Test'
              WHEN dc.IsValidCustomer =0 THEN 'eTorian' 
              WHEN  dat.AccountTypeID IN (7,13) THEN 'eTorian'
			  WHEN  dc.PlayerLevelID =4  THEN 'eTorian'
			  ELSE 'RealUser'
			  END 'UserType'
  , dat.Name as AccountType
  , ecpee.PositionInitialUnits
  , ecpee.PositionInitialAmountCents
 FROM EXW_dbo.EXW_C2P_E2E ecpee
 JOIN DWH_dbo.Dim_Customer dc 
 ON ecpee.GCID = dc.GCID
 JOIN DWH_dbo.Dim_AccountType dat
 ON dc.AccountTypeID = dat.AccountTypeID
 


 WHERE   
    LastModificationDate >=  <[Parameters].[Parameter 1]>
   
AND 
   LastModificationDate <= <[Parameters].[Start Date for Report (copy)_223772611717361664]>