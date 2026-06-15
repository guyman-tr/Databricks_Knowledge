select eccc.CID
	  ,eccc.GCID
	  ,[Reimbursement Rate]
	  ,[Date Rate For  Reimbursement]
	  ,CryptoName
	  ,CryptoId
	  ,[Reimbursement Coin Balance]
	  ,[Reimbursement USD Balance]
	  ,WalletId
	  ,Address
	  ,[Reimbursement Country]
	  ,ReimbursementCountryID
	  ,ReportFromDate
	  ,ReportId
	  ,Project
	  ,CompensationDate
	  ,[Reimbursement Regulation]
	  ,ReimbursementRegulationID
	  ,AMLStatus
	  ,[Current Country]
	  ,CurrentCountryID
	  ,CurrentRegulation
	  ,CurrentRegulationID
	  ,CurrentClub
	  ,UserRegion_State
	  ,IsTestAccount
	  ,AccountStatusName
	  ,AccountStatusID
	  ,PlayerStatusID
	  ,PlayerStatus
	  ,PlayerStatusReason
	  ,PlayerStatusSubReason
	  ,CurrentUSDRate
	  ,[Date of Current User Balance]
	  ,VerificationLevelID
	  ,UserWalletAllowance
	  ,UserWalletAllowanceBeginDate
	  ,DateForCurrentBalanceRate
	  ,[Current Coin Balance]
	  ,[Current USD Balance by Reimbursement Rate]
	  ,[Current USD Balance by Current Rate]
	  ,[Regulation Changed]
	  ,[Country Changed]
	  ,[Amount Change]
	  ,[Any Change]
	  ,[Non Zero Wallet]
	  ,PlatformUSDCompensationPerGCID
	  ,WalletDataUSDReimbursementPerGCID
	  ,WalletVsPlatform
	  ,MaxPlatformCreditDate
      ,TotalExtractedUnitsPerCrypto
	  ,TotalExtractedUSDPerCrypto
	  ,LastExtractionDatePerCrypto
	  , WalletEntity
	   FROM  EXW_dbo.EXW_ReimbursementFollowUp  eccc
	   LEFT JOIN EXW_dbo.EXW_WalletEntity ewe 
	   ON eccc.GCID = ewe.GCID  
	   AND CompensationDate =ewe.Date
	 WHERE 1=1
	  AND CompensationDate IS NOT  NULL 
	 AND [Reimbursement Coin Balance] >0
	  AND  ((eccc.Project IN ('AML_US','AML') AND LOWER(eccc.AMLStatus)   IN ( 'compensated','reimbursed', 'completed'))
				   OR eccc.Project NOT IN  ('AML_US','AML'))