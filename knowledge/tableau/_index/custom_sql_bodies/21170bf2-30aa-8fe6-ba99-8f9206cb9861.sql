SELECT a.Date date
		,a.Date
		,DATEFROMPARTS(YEAR(a.Date),MONTH(a.Date),1) ActiveDate
	  ,a.RealCID cid
	  ,a.AccountManager
	  ,a.Amount ActualContactDeposit
	  ,ActionType
FROM #Action a
WHERE a.ActionType in('InternalDeposit', 'Deposit')
AND a.Club = 'Platinum'