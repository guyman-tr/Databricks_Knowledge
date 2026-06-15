SELECT DISTINCT
	re.PaymentID
   ,re.ProviderPaymentID
	,CASE WHEN esc.Payment_ID IS NOT NULL THEN 1 ELSE 0 END AS ChargeBackTX
   ,esc.Chargeback_Type
   ,re.WalletID
   ,re.AmountInFiat
   ,re.FiatID
   ,re.CorrelationID
   ,re.RequestDate
   ,re.ModificationDate
   ,re.ExchangeRate
   ,re.ToAddress
   ,re.AmountInCrypto
   ,re.EtoroFeePercentage
   ,re.EtoroFeeCalculated
   ,re.ProviderFeeCalculated
   ,re.EstimatedBlockChainFee
   ,re.FiatName
   ,re.CryptoId
   ,re.CryptoName
   ,re.SentTransactionID
   ,re.ReceivedTransactionID
   ,re.BlockchainTransactionId
   ,re.PaymentStatus
   ,re.GCID
   ,du.Country
    ,du.Region
   ,re.RealCID
   ,re.BlockChainFee
   ,re.SimplexCurr
   ,re.SimplexAmountCurr
   ,re.SimplexProcessTime
   ,re.SimplexAmountUSD
   ,esm.status AS SimplexStatus
   ,re.ECPTranDate
   ,re.ECPPostDate
   ,re.ECPType
   ,re.Card
   ,re.ECPStatus
   ,re.ECPAmout
   ,re.ECPCommission
   ,re.ECPNetAmount
   ,re.ECPAdditionalCharge
   ,esm.uti AS UTI
   ,ft.SenderAddress
   ,iw.InternalType
   ,CASE WHEN du.IsTestAccount = 1 THEN 'TestUser'
		WHEN du.IsValidCustomer=0 THEN 'Etorian'
		ELSE 'RealUser'
	END AS UserType
	,sm.reason AS SimplexReason
	,sm.stage_drop AS SimplexStageDrop
	,sp.ShortName AS StateCode
	,sp.Name AS State
    ,dr.Name as Regulation
	,dc1.Name AS bin_country
	, esm.bank_name
   FROM [EXW_dbo].[EXW_PaymentReconciliation] re
	LEFT JOIN 
		EXW_dbo.EXW_SimplexMapping esm
			ON esm.long_id = re.ProviderPaymentID
	left join EXW_dbo.EXW_FactTransactions ft
		on re.SentTransactionID = ft.TranID and ActionTypeID = 1
	left join DWH_dbo.Dim_Customer dc
    on re.RealCID = dc.RealCID
	left join EXW_dbo.EXW_InternalWallet iw
		on ft.SenderAddress = iw.Address
	JOIN EXW_dbo.EXW_DimUser du
		ON re.GCID = du.GCID
	LEFT JOIN BI_DB_dbo.External_Fivetran_gsheets_wallet_exw_simplex_mapping sm ON esm.long_id = sm.long_id COLLATE Latin1_General_100_BIN
	join DWH_dbo.Dim_Regulation dr
	    on dc.RegulationID = dr.DWHRegulationID
	LEFT JOIN DWH_dbo.[Dim_State_and_Province] sp
		ON dc.RegionID = sp.RegionByIP_ID
	LEFT JOIN EXW_dbo.EXW_SimplexChargebacks esc
		ON re.ProviderPaymentID = esc.Payment_ID
	LEFT JOIN DWH_dbo.Dim_Country dc1 		ON sm.bin_country = dc1.Abbreviation COLLATE Latin1_General_100_BIN
-- WHERE re.RequestDateID >= CAST(CONVERT(VARCHAR(8), GETDATE()-30, 112) AS INT)