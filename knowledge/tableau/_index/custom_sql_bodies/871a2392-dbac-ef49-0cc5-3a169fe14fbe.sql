SELECT DISTINCT bdcdpc.CID
		,bdcdpc.LastTier
		,bdcdpc.CurrentTier
		,bdcdpc.AccountManagerID
		,dm.FirstName + ' ' + dm.LastName ManagerName
		,bdsmu.Team 
		,bdsmu.IsActive
		,bdsmu.Position
		,bdcdpc.UpdateDate
		,bdsmu.Name
		,CASE WHEN bduts.ActionName IS NOT NULL THEN 1 ELSE 0 END Contacted
		,MAX(bdcdpc.DateID) DateID
		,MAX(bdcdpc.Date) Date
FROM BI_DB_SF_M_Users bdsmu
LEFT JOIN BI_DB_CID_DailyPanel_Club bdcdpc
ON bdcdpc.AccountManagerID = bdsmu.AccountManagerID
AND bdcdpc.CurrentTier in (2,6,7)
AND bdcdpc.IsUpgrade = 1
AND bdcdpc.Date>EOMONTH(DATEADD(MONTH,-4,GETDATE()))
LEFT JOIN DWH.dbo.Dim_Manager dm
ON dm.ManagerID = bdcdpc.AccountManagerID
LEFT JOIN BI_DB_UsageTracking_SF bduts
ON bdcdpc.CID = bduts.CID
AND CAST(bduts.CreatedDate_SF AS DATE)>=DATEADD(dd,-30,bdcdpc.Date)
AND CAST(bduts.CreatedDate_SF AS DATE)<=bdcdpc.Date
AND bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c')
AND bduts.ManagerID = bdcdpc.AccountManagerID
WHERE bdsmu.ToDate = '9999-12-31'
GROUP BY bdcdpc.CID
		,bdcdpc.LastTier
		,bdcdpc.CurrentTier
		,bdcdpc.AccountManagerID
		,dm.FirstName + ' ' + dm.LastName 
		,bdsmu.Team 
		,bdsmu.IsActive
		,bdsmu.Position
		,bdcdpc.UpdateDate
		,CASE WHEN bduts.ActionName IS NOT NULL THEN 1 ELSE 0 END
		,bdsmu.Name