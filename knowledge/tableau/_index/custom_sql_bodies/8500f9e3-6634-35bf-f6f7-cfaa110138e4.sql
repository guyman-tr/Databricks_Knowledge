SELECT dc.AccountManagerID
		,dc.RealCID
		,dm.FirstName + ' ' +  dm.LastName AM
		,dpl.Name Club
                ,p.campaign_name
                ,(SELECT MAX(start_date)FROM 
                    #PI p 
                    ) start_date
                   ,p.CID
                ,(SELECT MAX(end_date)FROM 
                    #PI p 
                    ) end_date
				,us.Position
				,us.Team Region
                ,p.CID PI
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Manager dm
ON dm.ManagerID = dc.AccountManagerID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN [BI_DB_dbo].[External_BI_OUTPUT_Customer_Customer_Support_Agent_User] us
ON dc.AccountManagerID = cast (us.AccountManagerID AS BIGINT)
AND us.ToDate = '9999-12-31 00:00:00.0000000'
JOIN DWH_dbo.Dim_Country dc1
ON dc.CountryID = dc1.CountryID
LEFT JOIN #PI p
ON p.CID<>dc.RealCID
WHERE Position IN ('Senior Account Manager','Account Manager','Team leader')
AND dc.IsValidCustomer = 1