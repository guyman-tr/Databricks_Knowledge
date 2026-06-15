SELECT syn.FirstName+ ' ' + syn.LastName AM
	  ,syn.Desk Desk
	  ,dpl.Name Club
	  ,bdcdc.ClusterSF Classification
	  ,NULL AS AMType 
	  ,COUNT(distinct dc.RealCID) Customers
FROM [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
INNER JOIN [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User] syn 
ON dc.AccountManagerID = syn.AccountManagerID
INNER JOIN [DWH_dbo].[Dim_PlayerLevel] dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN BI_DB_dbo.BI_DB_CID_DailyCluster bdcdc WITH (NOLOCK)
ON dc.RealCID = bdcdc.CID
AND bdcdc.IsLastCluster=1
WHERE syn.IsActive = 'true'
AND syn.Position IN ('Account Manager','Trader AM','Senior Account Manager','Investor AM')
AND dc.IsValidCustomer = 1
AND syn.UserType != 'NULL' 
GROUP BY syn.FirstName+ ' ' + syn.LastName
	  ,syn.Desk
	  ,dpl.Name 
	  ,bdcdc.ClusterSF
	  ,syn.UserType