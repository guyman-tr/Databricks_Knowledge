SELECT
	fb.GCID
   ,fb.RealCID
   ,fb.BlockchainCryptoId as CryptoId
   ,fb.BlockchainCryptoName as CryptoName
   ,fb.InstrumentID
   ,fb.WalletID
  -- ,fb.TranID
--   ,fb.TranStatusID
 --  ,fb.TranStatus
   ,fb.TranDate
 --  ,fb.TranDateID
   ,fb.Amount
   ,fb.EtoroFees
   ,fb.ProviderFees
   ,fb.FeeExchangeRate
   ,fb.BlockchainFees
   ,fb.EstimatedBlockchainFee
   ,fb.ActionTypeID
   ,fb.ActionTypeName
   ,fb.AmountUSD
   ,fb.EtoroFeesUSD
 --  ,fb.BlockchainFeesUSD
  -- ,fb.EstimatedBlockchainFeesUSD
   ,fb.UpdateDate
 --  ,fb.SenderAddress
 --  ,fb.ReciverAddress
  -- ,fb.AMLProviderStatus
--   ,fb.AMLIsPositiveDecision
 --  ,fb.IsEtoroFee
 --  ,fb.BlockchainTransactionId
 --  ,fb.TransactionTypeID
--   ,fb.TransactionType
   ,fb.IsRedeem
   ,fb.IsConversion
   ,fb.IsPayment
   ,fb.CryptoId AS CryptoIdERC
   ,fb.CryptoName AS CryptoNameERC
   ,edu.Country
   ,edu.Region
   ,edu.Regulation
  -- ,dc.PlayerLevelID
   ,edu.Club
 --  ,dm.FirstName + ' ' + dm.LastName AS Manager
 , edu.ComplianceClosureEvent 
,CASE WHEN edu.IsTestAccount =1 THEN 'TestUser'    
   WHEN edu.IsValidCustomer =0 THEN 'eTorian'   
		ELSE 'RealUser'
	END AS RealUser
   ,edu.UserRegion_State AS State 
 FROM [EXW_dbo].[EXW_FactTransactions] fb with (NOLOCK)
LEFT JOIN EXW_dbo.EXW_DimUser edu  with (NOLOCK) ON edu.GCID =fb.GCID
--LEFT JOIN DWH_dbo.Dim_Customer dc with (NOLOCK)
--	ON fb.RealCID = dc.RealCID
--LEFT JOIN DWH_dbo.Dim_Country c with (NOLOCK)
--	ON dc.CountryID = c.CountryID
--LEFT JOIN DWH_dbo.[Dim_State_and_Province] sp with (NOLOCK)
--	ON dc.RegionID = sp.RegionByIP_ID
--LEFT JOIN DWH_dbo.Dim_Regulation dr with (NOLOCK)
--	ON dc.RegulationID = dr.DWHRegulationID
--LEFT JOIN DWH_dbo.Dim_PlayerLevel pl with (NOLOCK)
--	ON dc.PlayerLevelID = pl.PlayerLevelID
--LEFT JOIN DWH_dbo.Dim_Manager dm with (NOLOCK)
--	ON dc.AccountManagerID = dm.ManagerID
	where  fb.SenderAddress <>'0x5be786ad38f5846f605a8003550074cdfd4899a1' --sent promotion omnibus wallet
	AND isnull(fb.TransactionTypeID,99)   NOT IN (10,13)  --activation and extract