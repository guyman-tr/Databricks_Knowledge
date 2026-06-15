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
	  ,eaur.ScreeningStatus  'Pep Status'
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
	  ,eaur.LastTxDate 'Last Transaction Date'
	  ,eaur.ClosingProject
	  ,BalanceUSD  TotalBalanceUSD
	  FROM EXW_dbo.EXW_AML_Users_Report eaur
JOIN  [BI_DB_dbo].[External_Fivetran_google_sheets_aml_users_list]  j 
	  on j.amluser_id = eaur.ProviderUserIDNormalized COLLATE SQL_Latin1_General_CP1_CI_AS

 JOIN (SELECT Sum (BalanceUSD)BalanceUSD
              , efrbn.GCID 
			  FROM EXW_dbo.EXW_FinanceReportsBalancesNew efrbn 
              WHERE efrbn.BalanceDateID =  CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
			  GROUP BY GCID) b ON b.GCID =eaur.GCID