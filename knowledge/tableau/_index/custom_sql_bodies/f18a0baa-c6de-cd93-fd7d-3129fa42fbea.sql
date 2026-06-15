SELECT CID
      ,Date
	  ,DateID
      ,sc.AccountManagerID
	  ,CONCAT(dm.FirstName,' ',dm.LastName) Manager
	  ,isnull(UpgradePointsContacted,0) IsContacted
      ,isnull(UpgradePointsContacted,0) UpgradePointsContacted
      ,bu.UpgradeTypeContacted
	  ,dc.CurrentTier
	  ,ut.UpgradeType
	  ,CASE WHEN dc.CurrentTier = 5 THEN 'Bronze To Silver'
	        WHEN dc.CurrentTier = 3 THEN 'Bronze To Gold'
			WHEN dc.CurrentTier = 2 THEN 'Bronze To Platinum'
			WHEN dc.CurrentTier = 6 THEN 'Bronze To PlatinumPlus'
			WHEN dc.CurrentTier = 7 THEN 'Bronze To Diamond'
			ELSE NULL END AS UpgradeContacted
FROM BI_DB..BI_DB_CID_DailyPanel_Club dc
JOIN DWH..Dim_Customer sc
ON dc.CID = sc.RealCID 
LEFT JOIN [dbo].[BI_DB_ClubLevel_Bronze_Upgrade] bu
ON dc.CID = bu.RealCID
LEFT JOIN  [dbo].[BI_DB_ClubLevel_Bronze_UpgradeType] ut
ON ut.[UpgradeType] = bu.[UpgradeTypeContacted]
JOIN DWH..Dim_Manager dm
ON sc.AccountManagerID = dm.ManagerID
WHERE sc.AccountManagerID IN(3328,3158)
AND dc.IsUpgrade = 1 AND dc.LastTier = 1
AND sc.IsValidCustomer = 1