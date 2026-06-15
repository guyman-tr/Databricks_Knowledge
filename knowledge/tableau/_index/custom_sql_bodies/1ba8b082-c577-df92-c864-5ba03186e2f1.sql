SELECT
        fm.ProviderHolderID AS [ProviderHolderId]
      , fm.AccountID AS FiatAccountId
	  , fm.BankAccountID
	  , fm.CurrencyBalanceID
	  , fm.ProviderCurrencyBalanceID
	  , fm.GCID
	  , fm.CID RealCID
	  , fm.CardID
	 , fm.AccountProgram AS  Program
	 , fm.AccountSubProgram
	  , fm.Club

  FROM   eMoney_dbo.eMoney_Dim_Account fm
WHERE fm.GCID IN (18533455,20246348)