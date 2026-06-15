select eccc.CID
	  ,eccc.GCID
	  ,[Reimbursement Rate]
	 -- ,[Date Rate For  Reimbursement]
	  ,CryptoName
	  --,CryptoId
	  ,[Reimbursement Coin Balance]
	  ,[Reimbursement USD Balance]
	 -- ,WalletId
	  ,Address
	  ,[Reimbursement Country]
	 -- ,ReimbursementCountryID
	  ,ReportFromDate
	-- ,ReportId
	  ,Project
	  ,CompensationDate
	  ,[Reimbursement Regulation]
	--  ,ReimbursementRegulationID
	  ,AMLStatus
	  ,[Current Country]
	 -- ,CurrentCountryID
	  ,CurrentRegulation
	 -- ,CurrentRegulationID
	 -- ,CurrentClub
	  ,UserRegion_State
	 -- ,IsTestAccount
	 ,AccountStatusName
	--  ,AccountStatusID
	--  ,PlayerStatusID
	 -- ,PlayerStatus
	 -- ,PlayerStatusReason
	 -- ,PlayerStatusSubReason
	 -- ,CurrentUSDRate
	  ,ISNULL([Date of Current User Balance], '1999-01-01')[Date of Current User Balance]
	 -- ,VerificationLevelID
	  ,UserWalletAllowance
	 -- ,UserWalletAllowanceBeginDate
	 -- ,DateForCurrentBalanceRate
	  ,ISNULL([Current Coin Balance],0)[Current Coin Balance]
	  ,ISNULL([Current USD Balance by Reimbursement Rate],0)[Current USD Balance by Reimbursement Rate]
	  ,ISNULL([Current USD Balance by Current Rate],0)[Current USD Balance by Current Rate]
	  --,[Regulation Changed]
	  --,[Country Changed]
	  ,[Amount Change]
	  ,[Any Change]
	  ,[Non Zero Wallet]
	  ,PlatformUSDCompensationPerGCID
	  ,WalletDataUSDReimbursementPerGCID
	  ,WalletVsPlatform
	  --,MaxPlatformCreditDate
      ,TotalExtractedUnitsPerCrypto
	 -- ,TotalExtractedUSDPerCrypto
	  --,LastExtractionDatePerCrypto
	  ,ewe.WalletEntity  
	  , ewe2.WalletEntity CurrentWalletEntity
	   FROM  EXW_dbo.EXW_ReimbursementFollowUp  eccc
	   LEFT JOIN EXW_dbo.EXW_WalletEntity ewe 
	   ON eccc.GCID = ewe.GCID  
	   AND CompensationDate =ewe.Date
	    LEFT JOIN EXW_dbo.EXW_WalletEntity ewe2 
	   ON eccc.GCID = ewe2.GCID  
	   AND ewe2.Date =(SELECT max(Date) FROM EXW_dbo.EXW_WalletEntity)
	 WHERE 1=1
	 AND CompensationDate IS NOT  NULL 
	 AND [Reimbursement Coin Balance] >0
	  AND  (
     (eccc.Project LIKE 'AML%'  AND LOWER(eccc.AMLStatus)   IN ( 'compensated','reimbursed', 'completed'))
     OR eccc.Project NOT LIKE 'AML%')