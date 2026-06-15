SELECT cls.Classification 
	 ,dpl.Name Club
	 ,dc1.Desk
	 ,COUNT(dc.RealCID) Customers
FROM [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK)
ON dc.AccountManagerID = dm1.ManagerID
INNER JOIN [DWH].[dbo].[V_Liabilities] vl WITH (NOLOCK)
ON dc.RealCID = vl.CID
AND vl.DateID = CONVERT(CHAR(8),getdate()-1,112)
AND ISNULL(vl.ActualNWA,0) + ISNULL(vl.Liabilities,0) >25
INNER JOIN [DWH].[dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
LEFT JOIN BI_DB.dbo.BI_DB_Classification_Snapshot cls WITH (NOLOCK)
ON dc.RealCID = cls.RealCID
AND cls.LastSnapshot = 1
WHERE dc.IsValidCustomer = 1
AND dc.IsDepositor = 1
GROUP BY cls.Classification 
	 ,dpl.Name
	 ,dc1.Desk