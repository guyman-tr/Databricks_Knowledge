SELECT cp.Date
        ,cp.CID
	    ,cp.LastTier
		,cp.CurrentTier
		,cp.IsUpgrade
		,cp.DaysInClub
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
		,CASE WHEN LEAD(OptInDate) OVER (PARTITION BY cp.CID ORDER BY Date)  =Date THEN 1 ELSE 0 END OptedIn
		,CASE WHEN oi.CID IS NOT NULL THEN 1 ELSE 0 END OptInCurrent
  FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)	
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON cp.CID = dc.RealCID
  LEFT JOIN 
  (
  SELECT q0.CID ,[ValidFrom]
FROM 
(
SELECT [CID]
      ,[GCID]
      ,[ConsentStatusID]
      ,[ValidFrom]
      ,ROW_NUMBER() OVER (PARTITION BY [CID] ORDER BY [ValidFrom] DESC) rn
  FROM [BI_DB_dbo].[External_Trading_Trade_InterestConsent]
  WHERE [ValidFrom] <'20240430' /*new*/
  )q0
  WHERE rn = 1
  AND [ConsentStatusID] =1
  ) oi
  ON cp.CID = oi.CID
  WHERE cp.DateID >=20230103
  AND dc.PlayerLevelID IN (2,6,7)
  AND dc.IsValidCustomer = 1