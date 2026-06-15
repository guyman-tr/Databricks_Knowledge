SELECT dd.FullDate Date
        ,cp.[CID]
		,syn.desk Desk
		,dm1.FirstName +' '+dm1.LastName Manager
        ,dpl.Name NewClubTier
        ,ISNULL(dpl1.Name,'Bronze') PreviousClubTier
        ,ISNULL(dpl2.Name,'Bronze') MaxClubTier
        ,cp.[IsFTC]
        ,cp.[AmountToUpgrade]
		,CASE WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
        WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
        WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
        WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
        WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
        WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END as Region
    FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
	INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK) 
	ON cp.DateID = dd.DateKey
	INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
	ON cp.CurrentTier = dpl.PlayerLevelID
	INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
	ON cp.CID = dc.RealCID
	INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
    ON cp.CountryID = dc1.CountryID
	LEFT JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl1 WITH (NOLOCK)
	ON cp.[LastTier] = dpl1.PlayerLevelID
	INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl2 WITH (NOLOCK)
	ON cp.[MaxTier] = dpl2.PlayerLevelID
	LEFT JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn WITH (NOLOCK)
	ON dc.AccountManagerID = syn.manager_id
	LEFT JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK)
	ON dc.AccountManagerID = dm1.ManagerID
	WHERE cp.IsUpgrade = 1
