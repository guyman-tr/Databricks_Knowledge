SELECT c.RealCID
	  ,c.FromDateID
	  ,c.AccountManagerID
	  ,c.PlayerLevelID CurrentTier
	  ,c.LastTier
	  ,DATEADD(dd,-1,dd.FullDate) Date
		,cast(convert(varchar(8),DATEADD(dd,-1,dd.FullDate),112) as int) DateID
FROM 
(SELECT fsc.RealCID
		,dr.FromDateID
		,fsc.AccountManagerID
		,dr.ToDateID
		,fsc.PlayerLevelID
		,dpl.Sort currenttier
		,LAG(fsc.PlayerLevelID,1) OVER (PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ) LastTier
FROM DWH.dbo.Fact_SnapshotCustomer fsc
JOIN DWH.dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID
JOIN DWH.dbo.Dim_PlayerLevel dpl
ON fsc.PlayerLevelID = dpl.PlayerLevelID
JOIN (
SELECT DISTINCT fsc.RealCID
				,dr.FromDateID
FROM DWH.dbo.Fact_SnapshotCustomer fsc
JOIN DWH.dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID
WHERE dr.FromDateID >=20230101
AND fsc.IsDepositor = 1
AND fsc.PlayerLevelID IN (7,6,2,3)
) cc
ON fsc.RealCID = cc.RealCID
) c
JOIN DWH.dbo.Dim_PlayerLevel dpl
ON c.LastTier = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_Date dd
ON c.FromDateID = dd.DateKey
WHERE c.FromDateID >=20221201
AND c.currenttier>dpl.Sort
AND c.PlayerLevelID IN (2,3,6,7)