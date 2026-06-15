SELECT full_name AM
      ,cp.CID
	  ,dpl.Name CurrentTier
	  ,dpl1.Name ExpectedDowngradeTier
	  ,cp.ExpectedDowngradeDate
	  ,cp.RealizedEquity
	  ,cp.Equity
	  ,dcl.ClusterSF Classification
FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER JOIN [ThirdParty_Fivetran].[Fivetran].[gsheets].[customer_managers] syn WITH (NOLOCK)
ON cp.AccountManagerID = manager_id
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
ON cp.CurrentTier = dpl.PlayerLevelID
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl1 WITH (NOLOCK)
ON cp.ExpectedDowngradeTierLT = dpl1.PlayerLevelID
LEFT JOIN BI_DB.dbo.BI_DB_CID_DailyCluster dcl WITH (NOLOCK)
ON cp.CID = dcl.CID
AND IsSFCluster = 1
WHERE manager_type = 'Investor AM'
AND cp.CurrentTier IN (2,6,7)
AND cp.DateID = CONVERT(CHAR(8),getdate()-1,112)
AND cp.ExpectedDowngradeDate != '1900-01-01'
AND cp.ExpectedDowngradeTierLT IN (1,5,3)