SELECT mda.CurrencyBalanceID
	  ,mda.AccountID
	  ,mda.GCID
	  ,mda.CID
	  ,mda.ClubID
	  ,mda.Club
	  ,mda.ClubCategory
	  ,mda.RegulationID
	  ,mda.Regulation
	  ,mda.CountryID
	  ,mda.Country
	  ,mda.Region
	  ,mda.PlayerStatusID
	  ,mda.PlayerStatus
	  ,mda.IsValidETM
	  ,mda.IsValidCustomer
	  ,mda.IsTestAccount
	  ,mda.IsCancelledAccount
	  ,mda.GCID_Unique_Count
	  ,mda.TP_RegDate
	  ,mda.TP_FTDDate
	  ,mda.RegClubID
	  ,mda.RegClub
	  ,mda.RegClubCategory
	  ,mda.RegRegulationID
	  ,mda.RegRegulation
	  ,mda.RegCountryID
	  ,mda.RegCountry
	  ,mda.RegRegion
	  ,mda.RegPlayerStatusID
	  ,mda.RegPlayerStatus
	  ,mda.HasCustomerInfoChanged
	  ,mda.HasClubChanged
	  ,mda.HasRegulationChanged
	  ,mda.HasCountryChanged
	  ,mda.HasPlayerStatusChanged
	  ,mda.CurrencyBalanceISOCode
	  ,mda.CurrencyBalanceISODesc
	  ,mda.CurrencyBalanceCreateTime
	  ,mda.CurrencyBalanceCreateDate
	  ,mda.CurrencyBalanceCreateDateID
	  ,mda.CurrencyBalanceStatusID
	  ,mda.CurrencyBalanceStatus
	  ,mda.CurrencyBalanceStatusTime
	  ,mda.ProviderDesc
	  ,mda.ProviderCurrencyBalanceID
	  ,mda.BankAccountID
	  ,mda.BankAccountIsExternal
	  ,mda.BankAccountName
	  ,mda.BankAccountNumber
	  ,mda.BankAccountSortCode
	  ,mda.BankAccountIBAN
	  ,mda.BankAccountBIC
	  ,mda.AccountCreateTime
	  ,mda.AccountCreateDate
	  ,mda.AccountCreateDateID
	  ,mda.AccountStatusID
	  ,mda.AccountStatus
	  ,mda.AccountStatusTime
	  ,mda.AccountProgramID
	  ,mda.AccountProgram
	  ,mda.AccountSubProgramID
	  ,mda.AccountSubProgram
	  ,mda.ProviderHolderID
	  ,mda.Seniority_TP_RegDate
	  ,mda.Seniority_TP_FTDDate
	  ,mda.Seniority_eTM_RegDate
	  ,mda.HasCard
	  ,mda.CardID
	  ,mda.CardCreateTime
	  ,mda.CardCreateDate
	  ,mda.CardCreateDateID
	  ,mda.CardStatusID
	  ,mda.CardStatus
	  ,mda.CardStatusExpirationTime
	  ,mda.CardStatusTime
	  ,mda.ProviderCardID
	  ,efd.FMI_Date
	  ,efd.Seniority_FMI
	  ,efd.FMI_Time
	  ,efd.FMI_Source
	  ,efd.FMO_Date
	  ,efd.Seniority_FMO
	  ,efd.FMO_Time
	  ,efd.FMO_Target
	  ,efd.FMO_MOP
	  ,efd.LastSettledTXDate
	  ,efd.Seniority_LastTXDate
	  ,efd.FirstIBANSettledTXDate
	  ,efd.LastIBANSettledTXDate
	  ,efd.CardActivationTime
	  ,efd.FirstCardSettledTXDate
	  ,efd.LastCardSettledTXDate
	  ,efd.[1stActionDate]
	  ,efd.[1stActionType]
	  ,efd.[1stActionUSDApproxAmount]
	  ,efd.[2ndActionDate]
	  ,efd.[2ndActionType]
	  ,efd.[2ndActionUSDApproxAmount]
	  ,efd.[3rdActionDate]
	  ,efd.[3rdActionType]
	  ,efd.[3rdActionUSDApproxAmount]
	  ,efd.[4thActionDate]
	  ,efd.[4thActionType]
	  ,efd.[4thActionUSDApproxAmount]
	  ,efd.[5thActionDate]
	  ,efd.[5thActionType]
	  ,efd.[5thActionUSDApproxAmount]
	  ,efd.IBAN1stActionDate
	  ,efd.IBAN1stActionType
	  ,efd.IBAN1stActionUSDApproxAmount
	  ,efd.IBAN2ndActionDate
	  ,efd.IBAN2ndActionType
	  ,efd.IBAN2ndActionUSDApproxAmount
	  ,efd.IBAN3rdActionDate
	  ,efd.IBAN3rdActionType
	  ,efd.IBAN3rdActionUSDApproxAmount
	  ,efd.IBAN4thActionDate
	  ,efd.IBAN4thActionType
	  ,efd.IBAN4thActionUSDApproxAmount
	  ,efd.IBAN5thActionDate
	  ,efd.IBAN5thActionType
	  ,efd.IBAN5thActionUSDApproxAmount
	  ,efd.Card1stActionDate
	  ,efd.Card1stActionType
	  ,efd.Card1stActionUSDApproxAmount
	  ,efd.Card2ndActionDate
	  ,efd.Card2ndActionType
	  ,efd.Card2ndActionUSDApproxAmount
	  ,efd.Card3rdActionDate
	  ,efd.Card3rdActionType
	  ,efd.Card3rdActionUSDApproxAmount
	  ,efd.Card4thActionDate
	  ,efd.Card4thActionType
	  ,efd.Card4thActionUSDApproxAmount
	  ,efd.Card5thActionDate
	  ,efd.Card5thActionType
	  ,efd.Card5thActionUSDApproxAmount
	  ,efd.UpdateDate
          ,SUBSTRING(mda.BankAccountIBAN, PATINDEX('%[A-Z]%', mda.BankAccountIBAN), 2) AS IBAN_Code
FROM eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK)
LEFT JOIN eMoney_dbo.eMoney_Panel_FirstDates efd WITH(NOLOCK) ON mda.AccountID = efd.AccountID
WHERE  mda.GCID_Unique_Count=1