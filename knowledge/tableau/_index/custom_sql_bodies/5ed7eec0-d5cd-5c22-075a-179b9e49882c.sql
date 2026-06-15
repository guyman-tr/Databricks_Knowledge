SELECT f.AccountId
		   ,f.LastDateNonNegative
		   ,f.DaysinNegative
		   ,f.HolderId
		   ,f.SettledBalance
		   ,f.AvailableBalance
		   ,f.CurrencyIson
		   ,f.Currency
		   ,f.Date
		   ,f.Regulation
		   ,f.Club
		   ,f.Country
		   ,f.IsTestAccount
		   ,f.CurrencyBalanceStatus
		   ,f.GCID
		   ,f.CID
FROM #final f