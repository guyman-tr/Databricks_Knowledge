SELECT  a.Club,
    a.ActiveDate,
    a.AccountManager,
    a.Contacted,
a.ActionType,
a.AccountType,
a.RealCID,
a.Date,
max(Amount)Amount

	FROM #final a
	JOIN #base_query bq ON a.ActiveDate=bq.Date AND a.AccountManager=bq.account_manager
	--WHERE a.ActiveDate='2026-02-01' 
group BY 
a.Club,
    a.ActiveDate,
    a.AccountManager,
    a.Contacted,
a.ActionType,
a.AccountType,
a.RealCID,
a.Date