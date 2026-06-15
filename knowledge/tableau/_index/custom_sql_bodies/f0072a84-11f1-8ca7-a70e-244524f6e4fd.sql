SELECT  a.Club,
    a.ActiveDate,
    a.AccountManager,
    a.Contacted,
    a.TotalDeposits_ThisMonth,
    a.TotalCashouts_ThisMonth,
   a.TotalOpenfromIBAN_ThisMonth,
   a.TotalClosetoIBAN_ThisMonth,
    a.TotalCompensation_ThisMonth,
bq.position,
bq.region,
	MAX(CASE WHEN bq.type_of_kpi='Deposit' THEN target END ) AS Deposit_target,
	MAX(CASE WHEN bq.type_of_kpi='Cashout Ratio' THEN target END ) AS Cashout_Ratio_Benchmark
	FROM #final a
	JOIN #base_query bq ON a.ActiveDate=bq.Date AND a.AccountManager=bq.account_manager
	--WHERE a.ActiveDate='2026-02-01' 
	group BY a.Club,
    a.ActiveDate,
    a.AccountManager,
    a.Contacted,
    a.TotalDeposits_ThisMonth,
    a.TotalCashouts_ThisMonth,
   a.TotalOpenfromIBAN_ThisMonth,
   a.TotalClosetoIBAN_ThisMonth,
    a.TotalCompensation_ThisMonth,
bq.position,
bq.region