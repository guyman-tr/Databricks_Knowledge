SELECT c.RealCID CID
		, c.LastTier
		,c.PlayerLevelID CurrentTier
		,bdsmu.AccountManagerID
		,bdsmu.Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
	  ,c.FromDateID
	  ,CASE WHEN bduts.ActionName IS NOT NULL THEN 1 ELSE 0 END Contacted
	  ,dd.FullDate Date
	,cast(convert(varchar(8),dd.FullDate,112) as int) DateID
FROM  BI_DB_SF_M_Users bdsmu
	LEFT JOIN 
	(SELECT fsc.RealCID
			,dr.FromDateID
			,fsc.AccountManagerID
			,dr.ToDateID
			,fsc.PlayerLevelID
			,dpl.Sort currenttier
			,LAG(fsc.PlayerLevelID,1) OVER (PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ) LastTier
			,LAG(fsc.AccountManagerID,1) OVER (PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ) LastAM
	FROM DWH.dbo.Fact_SnapshotCustomer fsc
	LEFT JOIN DWH.dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID
	LEFT JOIN DWH.dbo.Dim_PlayerLevel dpl
	ON fsc.PlayerLevelID = dpl.PlayerLevelID
	LEFT JOIN 
			(
			SELECT DISTINCT fsc.RealCID
							,dr.FromDateID
			FROM DWH.dbo.Fact_SnapshotCustomer fsc
			LEFT JOIN DWH.dbo.Dim_Range dr
			ON fsc.DateRangeID = dr.DateRangeID
			WHERE dr.FromDateID >=20230101
			AND fsc.IsDepositor = 1
			AND fsc.PlayerLevelID IN (7,6,2,3,5)
			) 
		cc
		ON fsc.RealCID = cc.RealCID
	) c
ON bdsmu.AccountManagerID = c.LastAM
JOIN DWH.dbo.Dim_PlayerLevel dpl
ON c.LastTier = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_Date dd
ON c.FromDateID = dd.DateKey
AND c.FromDateID >=20221201
AND c.currenttier>dpl.Sort
AND c.PlayerLevelID IN (2,3,6,7,5)
LEFT JOIN BI_DB_UsageTracking_SF bduts
ON c.RealCID = bduts.CID
AND CAST(bduts.CreatedDate_SF AS DATE)>=DATEADD(dd,-30,dd.FullDate)
AND CAST(bduts.CreatedDate_SF AS DATE)<=dd.FullDate
AND bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c')
--AND bduts.ManagerID = c.AccountManagerID
WHERE bdsmu.ToDate = '9999-12-31'