SELECT mdt.TransactionID
	  ,mdt.AccountID
	  ,mdt.GCID
	  ,mdt.CID
	  ,mdt.CardID
	  ,mdt.ProviderCardID
	  ,mdt.CurrencyBalanceID
	  ,mdt.ProviderCurrencyBalanceID
	  ,mdt.ExternalBankAccountID
	  ,mdt.TxTypeID
	  ,mdt.TxType
	  ,mdt.TxTypeCategory
	  ,mdt.TxClientBalanceCategory
	  ,mdt.MerchantID
	  ,mdt.TxCreatedDate
	  ,mdt.TxCreatedDateID
	  ,mdt.TxLabel
	  ,mdt.TxLocalTime
	  ,mdt.TxLocalDate
	  ,mdt.TxLocalDateID
	  ,mdt.ReferenceNumber
	  ,mdt.TxCategoryID
	  ,mdt.TxCategory
	  ,mdt.PaymentSchemaTypeID
	  ,mdt.PaymentSchemaType
	  ,mdt.PaymentReference
	  ,mdt.ProviderID
	  ,mdt.ProviderDesc
	  ,mdt.ProviderTransactionID
	  ,mdt.AccountProgramID
	  ,mdt.AccountProgram
	  ,mdt.AccountSubProgramID
	  ,mdt.AccountSubProgram
	  ,mdt.IsValidETM
	  ,mdt.IsValidCustomer
	  ,mdt.ClubIDTxDate
	  ,mdt.ClubTxDate
	  ,mdt.RegulationIDTxDate
	  ,mdt.RegulationTxDate
	  ,mdt.CountryIDTxDate
	  ,mdt.CountryTxDate
	  ,mdt.PlayerStatusIDTxDate
	  ,mdt.PlayerStatusTxDate
	  ,mdt.IsTxSettled
	  ,mdt.TxStatusID
	  ,mdt.TxStatus
	  ,mdt.CountStatusChanges
	  ,mdt.AuthorizationTypeID
	  ,mdt.AuthorizationType
	  ,mdt.IsTxStatusCBRelevant
	  ,mdt.MoneyMoveDirection
	  ,mdt.HolderCurrencyISO
	  ,mdt.HolderCurrencyDesc
	  ,mdt.HolderAmount
	  ,mdt.LocalCurrencyISO
	  ,mdt.LocalCurrencyDesc
	  ,mdt.LocalAmount
	  ,mdt.USDAmountApprox
	  ,mdt.USDRateApprox
	  ,mdt.AccumulatedAmount
	  ,mdt.AccumulatedUSDAmountApprox
	  ,mdt.TxStatusModificationTime
	  ,mdt.TxStatusModificationDate
	  ,mdt.TxStatusModificationDateID
	  ,mdt.TxStatusCreatedDate
	  ,mdt.TxStatusCreatedDateID
	  ,mdt.RiskRuleCodes
	  ,mdt.MarkTransactionAsSuspiciousRiskAction
	  ,mdt.ChangeCardStatusToRiskRiskAction
	  ,mdt.ChangeAccountStatusToSuspendedRiskAction
	  ,mdt.RejectTransactionRiskAction
	  ,mdt.UpdateDate
	  ,mda.RegClub
	  ,mda.RegClubCategory
          ,mda.RegCountryID
	  ,mda.RegCountry
	  ,mda.RegRegion
	  ,mda.RegPlayerStatus
FROM eMoney.dbo.eMoney_Dim_Transaction mdt
LEFT JOIN eMoney.dbo.eMoney_Dim_Account mda ON mdt.AccountID = mda.AccountID