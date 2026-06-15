SELECT eaur.GCID
	  ,eaur.RealCID
	  ,eaur.Country
	  ,eaur.IsValidCustomer
	  ,eaur.VerificationLevelID  'Verification Level'
	  ,eaur.JoinDate
	  ,eaur.PlayerStatusID
	  ,eaur.CurrentPlayerStatus  'Player Status'
	  ,eaur.Regulation
	  ,eaur.StatusChangeDate
	  ,eaur.CountryByIP
	  ,eaur.PlayerStatusReason
	  ,eaur.PlayerStatusSubReason
	  ,eaur.CountryID
	  ,eaur.RiskClassificationID
	  ,eaur.IsUS
	  ,eaur.Age
	  ,eaur.BirthDate
	  ,eaur.RiskStatus
	  ,eaur.ScreeningStatus  'Screening Status'
	  ,eaur.ScreeningStatusID
	  ,eaur.RiskClassificationName
	  ,eaur.ProviderUserIDNormalized
	  ,eaur.ProviderUserID
	  ,eaur.AMLProviderID
	  ,eaur.AccountType
	  ,eaur.IsRealUser
	  ,eaur.UserWalletAllowance
	  ,eaur.AccountStatus
	  ,eaur.CountryRankID
	  ,eaur.CountryRankDescription  'Country Risk'
          ,eaur.ClosingProject
  ,ewe.WalletEntity
FROM EXW_dbo.EXW_AML_Users_Report eaur
LEFT JOIN EXW_dbo.EXW_WalletEntity ewe ON eaur.GCID = ewe.GCID
AND ewe.DateID = ( SELECT max (DateID) FROM EXW_dbo.EXW_WalletEntity )