SELECT dp.CID
		,dp.Date FirstDate
		,dp1.Date Lastdate
		,dp1.CurrentTier 
		,dp1.LastTier 
		,bdsmu.Name ManagerNameFromUser
		,dm.FirstName + ' ' + dm.LastName ManagerName
		,bdsmu.Team Desk
		,bdsmu.Position
		,bdsmu.IsActive
		,dp1.IsDowngrade
FROM BI_DB_CID_DailyPanel_Club dp
LEFT JOIN BI_DB_CID_DailyPanel_Club dp1
ON dp.CID = dp1.CID
AND dp1.Date = DATEADD(dd,-1,DATEADD(mm,4,dp.Date))
LEFT JOIN BI_DB_CID_DailyPanel_Club dp2
ON dp.CID = dp2.CID
AND dp2.Date = DATEADD(dd,-1,dp.Date)
LEFT JOIN DWH.dbo.Dim_Date dd
ON dd.FullDate = dp.Date
LEFT JOIN BI_DB_SF_M_Users bdsmu
ON dp.AccountManagerID = bdsmu.AccountManagerID
AND  dp.Date>=bdsmu.FromDate
AND dp.Date<=bdsmu.ToDate
LEFT JOIN DWH.dbo.Dim_Manager dm
ON dm.ManagerID = dp.AccountManagerID
WHERE dp.Date>=DATEADD(mm,-7,GETDATE())
AND dp.Date <=DATEADD(mm,-4,GETDATE())
AND dd.IsFirstDayOfMonth = 'Y'
AND dp.CurrentTier>5
AND dp2.IsFundedCurrentTier = 1