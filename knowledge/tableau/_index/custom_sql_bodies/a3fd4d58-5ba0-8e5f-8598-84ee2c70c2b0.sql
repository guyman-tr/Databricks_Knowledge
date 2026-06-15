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
,BalanceUSD
FROM EXW_dbo.EXW_AML_Users_Report eaur
left join #users u on u.GCID =  eaur.GCID  
JOIN EXW_dbo.EXW_WalletEntity ewe 
ON eaur.GCID = ewe.GCID  
AND ewe.DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
JOIN (SELECT Sum (BalanceUSD)BalanceUSD
              , efrbn.GCID 
			  FROM EXW_dbo.EXW_FinanceReportsBalancesNew efrbn 
              WHERE efrbn.BalanceDateID =  CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
			  GROUP BY GCID) b ON b.GCID =eaur.GCID
WHERE (eaur.ClosingProject IS NOT NULL AND eaur.ClosingProject <> 'XtokensClosure' )OR u.GCID IS NOT NULL