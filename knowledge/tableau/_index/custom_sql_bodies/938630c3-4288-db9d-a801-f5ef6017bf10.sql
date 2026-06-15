SELECT bdsmu.AccountManagerID
		,bdsmu.FirstName +' '+ LastName AS Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
	,bduts.ActionName
	,bduts.CreatedDate_SF
	,bduts.CID
	,bduts.ID
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT JOIN BI_DB_dbo.BI_DB_UsageTracking_SF bduts
ON bduts.CreatedByManagerID = bdsmu.AccountManagerID
AND bduts.CreatedDate_SF>=DATEADD(mm,-5,GETDATE())
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'