SELECT RealCID
      ,dpl.Name CurrentTier
	  ,dpl1.Name ExpectedDownGradeTier
	  ,dpl2.Name HighestTier 
      ,cp.AmountToRemain
	  ,cp.RealizedEquity
	  ,cp.Equity
	  ,cp.Classification
	  ,syn.desk
	  ,cp.IsFTC
	  ,cp.DaysFromFTD
	  ,cp.DaysInClub
	  ,cp.DaysInCurrentClub
      ,dm1.FirstName +' '+dm1.LastName Manager
	  ,CASE WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
        WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
        WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
        WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
        WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
        WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END as Region
FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON cp.CountryID = dc1.CountryID
INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
ON cp.CID = dc.RealCID
INNER JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK)
ON cp.AccountManagerID = dm1.ManagerID
INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
ON cp.DateID = dd.DateKey
INNER JOIN DWH.dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON cp.CurrentTier = dpl.PlayerLevelID
INNER JOIN DWH.dbo.Dim_PlayerLevel dpl1 WITH (NOLOCK)
ON cp.ExpectedDowngradePlayerLevelID = dpl1.PlayerLevelID
INNER JOIN DWH.dbo.Dim_PlayerLevel dpl2
ON dpl2.PlayerLevelID = cp.MaxTier
LEFT JOIN [BI_DB].[dbo].[BI_DB_AccountManagers_List] syn WITH (NOLOCK)
ON dc.AccountManagerID = syn.manager_id
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND cp.IsExpectedDowngrade = 1