SELECT e.GCID
	  ,e.RealCID
	  ,e.Country
	  ,e.IsValidCustomer
	  ,e.VerificationLevelID
	  ,e.JoinDate
	  ,e.PlayerStatusID
	  ,e.CurrentPlayerStatus
	  ,e.StatusChangeDate
	  ,e.CountryByIP
	  ,e.PlayerStatusReason
	  ,e.PlayerStatusSubReason
	  ,e.Regulation
	  ,e.CountryID
	  ,e.RiskClassificationID
	  ,e.IsUS
	  ,e.Age
	  ,e.BirthDate
	  ,e.RiskStatus
	  ,e.ScreeningStatus
	  ,e.ScreeningStatusID
	  ,e.RiskClassificationName
	  ,e.ProviderUserIDNormalized
	  ,e.ProviderUserID
	  ,e.AMLProviderID
	  ,e.IsRealUser
	  ,e.UserWalletAllowance
	  ,e.AccountStatus
	  ,e.AccountType
	  ,e.Club
	  ,e.FirstDepositDate
	  ,e.EvMatchStatus
	  ,e.ClosingProject
	  ,e.CountryRankID
	  ,e.AMLComment
	  ,e.RiskComment
	  ,e.CountryRankDescription
	  ,e.Occupation
	  ,e.HasCryptoTransfer
	  ,e.HasPayments
	  ,e.HasRiskCountryLogins
	  ,e.IsAMLProblematic
	  ,e.RelatedCIDs
	  ,e.UpdateDate
	  ,e.RiskScore
	  ,e.RiskScore_Explanation
	  ,e.RiskScoreName
	  ,e.FirstTxDate
	  ,e.LastTxDate
	  ,e.ScreeningStatusID_Ext
	  ,e.ScreeningStatusExt
	  ,e.ScreeningBeginTime_Ext
	  ,e.WalletBalanceUSD
	  ,d.IsEuropeanCountry
          ,ewe.WalletEntity
          ,l.aml_compliance  
 
	  FROM EXW_dbo.EXW_AML_Users_Report e 
JOIN DWH_dbo.Dim_Country   d 
ON e.CountryID =d.CountryID
left JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_grc_list] l
ON l.country = e.Country
left JOIN EXW_dbo.EXW_WalletEntity ewe 
ON e.GCID = ewe.GCID 
AND ewe.DateID  = ( SELECT max(DateID) FROM EXW_dbo.EXW_WalletEntity)
 WHERE e.JoinDate >= <[Parameters].[Parameter 1]>