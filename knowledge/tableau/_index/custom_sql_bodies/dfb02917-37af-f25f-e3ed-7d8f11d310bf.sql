SELECT * FROM 
  (
  SELECT cp.Date
        ,cp.CID
	    ,cp.LastTier
		,cp.CurrentTier
		,cp.IsUpgrade
		,cp.DaysInClub
		,cp.DaysInCurrentClub
		,cp.RealizedEquity
		,cp.Equity
		,cp.RealizedEquityClub
		,cp.DepositAmount
		,cp.DepositTransactions
		,cp.WithdrawAmount
		,cp.WithdrawTransactions
		,cp.IsOptInInterest
		,cp.OptInDate
		,dc.PlayerLevelID CurrentTierLast
		,CASE WHEN LEAD(OptInDate) OVER (PARTITION BY CID ORDER BY Date)  =Date THEN 1 ELSE 0 END OptedIn
		,DATEDIFF(DAY,MAX(cp.OptInDate) OVER (PARTITION BY CID),Date) DateDiffOptUp
		,cp.MaxTier
		,YEAR(cp.OptInDate) OptinYear
  FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)	
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON cp.CID = dc.RealCID
  WHERE cp.DateID >=20230101
  --AND cp.CID = 12670767
  AND dc.PlayerLevelID IN (2,6,7)
  AND dc.IsValidCustomer = 1
  AND dc.UserName_Lower NOT LIKE '%test%'
  )q0
  WHERE q0.IsUpgrade = 1