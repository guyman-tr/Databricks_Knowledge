SELECT tt.CID
	  ,tt.FirstDate
	  ,tt.ManagerNameFromUser
	  ,tt.ManagerName
	  ,tt.Desk
	  ,tt.Position
	  ,tt.IsActive
	  ,bdcdpc.Date
	  ,bdcdpc.IsExpectedDowngrade
	  ,bdcdpc.IsFundedCurrentTier
	  ,bdcdpc.CurrentTier
	  ,bdcdpc.ExpectedDowngradePlayerLevelID
	  ,dpl.Name CurrentClub
	  ,dpl1.Name ExpectedDowngrade
            ,tt.AccountManagerID
FROM (SELECT dp.CID
		,dp.Date FirstDate
		,bdsmu.Name ManagerNameFromUser
		,dm.FirstName + ' ' + dm.LastName ManagerName
		,bdsmu.Team Desk
		,bdsmu.Position
		,bdsmu.IsActive
                ,dp.AccountManagerID
FROM BI_DB_CID_DailyPanel_Club dp
LEFT JOIN DWH.dbo.Dim_Date dd
ON dd.FullDate = dp.Date
LEFT JOIN BI_DB_SF_M_Users bdsmu
ON dp.AccountManagerID = bdsmu.AccountManagerID
AND  dp.Date>=bdsmu.FromDate
AND dp.Date<=bdsmu.ToDate
LEFT JOIN DWH.dbo.Dim_Manager dm
ON dm.ManagerID = dp.AccountManagerID
WHERE dp.Date>=DATEADD(mm,-4,GETDATE())
AND dd.IsFirstDayOfMonth = 'Y'
AND dp.CurrentTier>5
AND dp.IsFundedCurrentTier = 1) tt
JOIN BI_DB_CID_DailyPanel_Club bdcdpc
ON bdcdpc.CID = tt.CID
JOIN DWH.dbo.Dim_PlayerLevel dpl
ON dpl.PlayerLevelID = bdcdpc.CurrentTier
JOIN DWH.dbo.Dim_PlayerLevel dpl1
ON dpl1.PlayerLevelID = bdcdpc.ExpectedDowngradePlayerLevelID
WHERE bdcdpc.Date>=tt.FirstDate
AND bdcdpc.Date<DATEADD(mm,4,tt.FirstDate)