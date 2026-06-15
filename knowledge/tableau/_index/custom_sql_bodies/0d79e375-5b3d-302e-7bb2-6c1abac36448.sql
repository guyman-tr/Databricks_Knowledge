SELECT dc.RealCID, dm.FirstName, dm.LastName
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Manager dm
	ON dc.AccountManagerID = dm.ManagerID