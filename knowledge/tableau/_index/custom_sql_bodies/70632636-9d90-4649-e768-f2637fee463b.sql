SELECT	bdcdpc.CID
		,dpl.Name ExpectedDowngradeTier
		,dpl1.Name CurrentTier
		,dm.FirstName + ' ' + dm.LastName AM
		,bdcdpc.AmountToRemain
	  ,CASE WHEN dc1.Name IN ('Netherlands','Netherlands Antilles') THEN 'Netherlands'
       WHEN dc1.Name IN ('Mexico') THEN 'Mexico'
       WHEN dc1.Name IN ('Romania') THEN 'Romania'
       WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
       WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
       WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
       WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
       WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
       WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END AS Region
FROM BI_DB_CID_DailyPanel_Club bdcdpc
JOIN DWH.dbo.Dim_PlayerLevel dpl
ON bdcdpc.ExpectedDowngradePlayerLevelID = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_PlayerLevel dpl1
ON bdcdpc.CurrentTier = dpl1.PlayerLevelID
JOIN DWH.dbo.Dim_Manager dm
ON dm.ManagerID = bdcdpc.AccountManagerID
JOIN DWH.dbo.Dim_Country dc1
ON bdcdpc.CountryID = dc1.CountryID
WHERE bdcdpc.Date = DATEADD(DAY,-1,CONVERT(DATE, GETDATE())) 
AND bdcdpc.IsExpectedDowngrade = 1