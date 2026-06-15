SELECT
	fs.GCID
   ,fs.RealCID
   ,fs.BlockchainCryptoId as CryptoId
   ,fs.BlockchainCryptoName as CryptoName
   ,fs.InstrumentID
   ,fs.WalletID
   ,fs.TranID
   ,fs.TranStatusID
   ,fs.TranStatus
   ,fs.TranDate
   ,fs.TranDateID
   ,fs.Amount
   ,fs.EtoroFees
   ,fs.ProviderFees
   ,fs.FeeExchangeRate
   ,fs.BlockchainFees
   ,fs.EstimatedBlockchainFee
   ,fs.ActionTypeID
   ,fs.ActionTypeName
   ,fs.AmountUSD
   ,fs.EtoroFeesUSD
   ,fs.BlockchainFeesUSD
   ,fs.EstimatedBlockchainFeesUSD
   ,fs.SenderAddress
   ,fs.ReciverAddress
   ,fs.AMLProviderStatus
   ,fs.AMLIsPositiveDecision
   ,fs.IsEtoroFee
   ,fs.BlockchainTransactionId
   ,fs.TransactionTypeID
   ,fs.TransactionType
   ,fs.IsRedeem
   ,fs.IsConversion
   ,fs.IsPayment
   ,fs.CryptoId AS CryptoIdERC
   ,fs.CryptoName AS CryptoNameERC
   ,du.Region
   ,pu.ProviderUserID
   ,pu.ProviderUserIDNormalized
   ,CASE
		WHEN fs.GCID <= 0 THEN 'Omnibus'
		WHEN 	du.IsTestAccount =1      THEN 'TestAccount'
		WHEN  dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
   ,du.Country
   ,du.Regulation
   ,CASE
		WHEN DATEDIFF(YEAR, dc.BirthDate, GETDATE()) BETWEEN 18 AND 22 THEN '18-22'
		WHEN DATEDIFF(YEAR, dc.BirthDate, GETDATE()) > 65 THEN '65+'
		ELSE '22-65'
	END AS AgeBins
   ,dc1.IsHighRiskCountry
   ,dc1.RiskGroupID CountryRiskGroup
   ,ps.Name AS PlayerStatus
  -- ,CASE WHEN tc.Occurred IS NOT NULL THEN 1 ELSE 0	END AS SignedTNC
   ,das.AccountStatusName AS AccountStatus
   ,du.UserRegion_State AS State
FROM EXW_dbo.EXW_FactTransactions fs
LEFT JOIN EXW_dbo.EXW_DimUser du
	ON fs.GCID = du.GCID
LEFT JOIN DWH_dbo.Dim_Country dc1 ON du.CountryID = dc1.CountryID
LEFT JOIN DWH_dbo.Dim_Customer dc
	ON du.RealCID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps
	ON dc.PlayerStatusID = ps.PlayerStatusID
--LEFT JOIN [dbo].[EXW_TermsAndConditions] tc ON dc.GCID = tc.GCID
LEFT JOIN DWH_dbo.Dim_AccountStatus das
	ON dc.AccountStatusID = das.AccountStatusID
LEFT JOIN EXW_dbo.EXW_AMLProviderID   pu ON fs.GCID = pu.GCID
WHERE   fs.TranDateID >= <[Parameters].[big TX threshold (copy)]>
AND fs.TranDateID <= <[Parameters].[First Date for Report. Format YYYYMMDD (copy)]>
--ORDER BY fs.TranPendingDate
--SELECT * FROM EXW_dbo.EXW_AMLProviderID