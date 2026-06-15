SELECT DISTINCT 
      eaa.WorkDate
      ,eaa.IssuerIdentificationNumber
      ,eaa.ProgramName
      ,eaa.ProgramId
      ,eaa.ProductName
      ,eaa.ProductId
      ,eaa.SubProductId
      ,eaa.HolderId
      ,eaa.AccountId
      ,eaa.BankAccountId
      ,eaa.ExternalBankAccountId
      ,eaa.BankAccountNumber
      ,eaa.BankAccountSortCode
      ,eaa.BankAccountIban
      ,eaa.BankAccountBic
      ,eaa.CardNumber
      ,eaa.CardNumberId
      ,eaa.CardRequestId
      ,eaa.Bin
      ,eaa.TransactionCode
      ,eaa.TransactionCodeDescription
      ,eaa.TransactionDateTime
      ,eaa.TransactionAmount
      ,eaa.TransactionCurrencyCode
      ,eaa.TransactionCurrencyAlpha
      ,eaa.TransLink
      ,eaa.TraceId
      ,eaa.TransactionCodeIdentifier
      ,eaa.HolderAmount
      ,eaa.HolderCurrencyAlpha
      ,eaa.FxRate
      ,eaa.FeeGroupId
      ,eaa.FeeGroupName
      ,eaa.FxFeeAmount
      ,eaa.FxFeeName
      ,eaa.FxFeeCurrency
      ,eaa.FxFeeReason
      ,eaa.F0FeeName
      ,eaa.F0FeeAmount
      ,eaa.F0FeeCurrency
      ,eaa.F0FeeReason
      ,eaa.BillRateAmount
      ,eaa.BillingDate
      ,eaa.BillingAmount
      ,eaa.BillingCurrencyCode
      ,eaa.BillingCurrencyAlpha
      ,eaa.SettlementAmount
      ,eaa.SettlementCurrencyCode
      ,eaa.SettlementCurrencyAlpha
      ,eaa.SettlementConversionRate
      ,eaa.CardPresent
      ,eaa.TransactionId
      ,eaa.TransactionClass
      ,eaa.Action
      ,eaa.Network
      ,eaa.TransactionDescription
      ,eaa.EntryModeCode
      ,eaa.EntryModeCodeDescription
      ,eaa.ReferenceNumber
      ,eaa.CountryIson
      ,eaa.LoadType
      ,eaa.LoadSource
      ,eaa.EpmMethodId
      ,eaa.EpmTransactionId
      ,eaa.DateID
                  FROM eMoney_dbo.ETL_AccountsActivities eaa 
	  JOIN eMoney_dbo.eMoney_Dim_Account mda  ON eaa.HolderId=mda.ProviderHolderID and mda.IsValidETM=1 AND mda.GCID_Unique_Count=1 
      LEFT  JOIN EXW_dbo.EXW_WalletEntity w ON mda.GCID = w.GCID AND eaa.Date = w.Date
	

    WHERE eaa.Date >= <[Parameters].[Parameter 2]>
   AND eaa.Date <= <[Parameters].[Parameter 3]>