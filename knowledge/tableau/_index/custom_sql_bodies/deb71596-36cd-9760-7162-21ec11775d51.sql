SELECT cp.CID
       ,dpl.Name CurrentClubTier
	   ,dpl1.Name PreviousClubTier
	   ,dpl2.Name MaxClubTier
	   ,cp.RealizedEquity
	   ,cp.Equity
	   ,cp.Classification
	   ,NbVerificationTickets
	   ,NbAMLTickets
	   ,dm1.FirstName + ' '+ dm1.LastName AM
	   ,dc1.Name Country
FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
ON cp.CurrentTier = dpl.PlayerLevelID
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl1 WITH (NOLOCK)
ON cp.LastTier = dpl1.PlayerLevelID
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl2 WITH (NOLOCK)
ON cp.MaxTier = dpl2.PlayerLevelID
INNER JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK)
ON cp.AccountManagerID = dm1.ManagerID
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON cp.CountryID = dc1.CountryID
	OUTER APPLY 
	(
	SELECT   SUM(CASE WHEN sfc.ActionType = 'Verification' THEN 1 ELSE 0 END) NbVerificationTickets
			,SUM(CASE WHEN sfc.ActionType = 'AML' THEN 1 ELSE 0 END) NbAMLTickets
	FROM [BI_DB].[dbo].[BI_DB_SF_Cases] sfc WITH (NOLOCK)
	where cp.CID = sfc.CID
	AND sfc.ActionType in ('Verification','AML') 
	GROUP BY DateID
	)oa
WHERE cp.MaxTier = 7
AND cp.DateID =   (SELECT MAX(DateID)
  FROM [BI_DB].[dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK))