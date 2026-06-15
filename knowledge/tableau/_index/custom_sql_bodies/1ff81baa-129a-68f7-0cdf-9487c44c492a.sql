SELECT bdsmu.AccountManagerID
		,bdsmu.Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
	,bduts.ActionName
	,bduts.CreatedDate_SF
	,bduts.CID
	,bduts.ID
FROM  BI_DB_SF_M_Users bdsmu
LEFT JOIN BI_DB_UsageTracking_SF bduts
ON bduts.CreatedByManagerID = bdsmu.AccountManagerID
AND bduts.CreatedDate_SF>=DATEADD(mm,-5,GETDATE())
WHERE bdsmu.ToDate = '9999-12-31'