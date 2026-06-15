SELECT Club
	  ,ActiveDate
	  ,AccountManager
	  ,Contacted
	  ,SUM(TotalDeposits_ThisMonth_IBAN) TotalDeposits_ThisMonth_IBAN
	  ,SUM(TotalCashouts_ThisMonth_IBAN) TotalCashouts_ThisMonth_IBAN
FROM #MIMO_IBAN_CID_with_contact
GROUP BY Club
	  ,ActiveDate
	  ,AccountManager
	  ,Contacted