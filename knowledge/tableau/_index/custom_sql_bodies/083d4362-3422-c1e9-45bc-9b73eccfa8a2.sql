SELECT dc.RealCID
		,bdcdpc.Date
		,bdcdpc.CurrentTier
		,bdcdpc.LastTier
		,dpl.Name CurrentClub
		,dpl1.Name LastClub
FROM DWH_dbo.Dim_Customer dc
JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_Club bdcdpc
ON bdcdpc.CID = dc.RealCID
AND bdcdpc.Date>='20230101'
JOIN DWH_dbo.Dim_Date dd
ON bdcdpc.DateID = dd.DateKey
AND (dd.IsLastDayOfMonth = 'Y' or dd.FullDate=CAST( dateadd(dd,-2,GetDate()) AS DATE))
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dpl.PlayerLevelID = bdcdpc.CurrentTier
JOIN DWH_dbo.Dim_PlayerLevel dpl1
ON dpl1.PlayerLevelID = bdcdpc.LastTier
WHERE dc.AffiliateID = 83543
AND dc.RegisteredReal>='20230101'
AND dd.FullDate>='20230101'