SELECT COALESCE(q1.CID,q2.CID) CID
      ,COALESCE(q1.AM,q2.AM) AM
	  ,ISNULL(q1.UserName,'Aukie2008') UserName
	  ,CASE WHEN MAX(q1.ActiveWatchlist) = 1 THEN 'InWatchlist' 
			WHEN MAX(q1.ActiveWatchlist) = 0 THEN 'PastWatchlists' 
			WHEN MAX(q1.ActiveWatchlist) IS NULL THEN 'NeverFollow' END ActiveWatchlist
	  ,CASE WHEN MAX(q1.ActiveCopy) = 1 THEN 'ActiveCopy' 
			WHEN MAX(q1.ActiveCopy) = 0 THEN 'CopyInPast' 
			WHEN MAX(q1.ActiveCopy) IS NULL THEN 'NeverCopy' END ActiveCopy
	  ,MAX(ISNULL(q2.Is20PercBalance,0)) Is20PercBalance
	  ,sum(vl.RealizedEquity) RealizedEquity_14Jan2024
	  ,SUM(vl.Equity) Equity_14Jan2024
	  ,SUM(vl.Credit) Credit_14an2024
	  ,SUM(ISNULL(c.EquityCopy,0)) EquityCopy_14Jan2024
FROM 
(SELECT q0.CID
	  ,q0.UserName
	  ,q0.AM
	  ,MAX(q0.ActiveWatchlist) ActiveWatchlist
	  ,MAX(q0.ActiveCopy)  ActiveCopy
FROM 
(
SELECT wl.CID
      ,AM
	  ,dc1.UserName UserName
	  ,MAX(CASE WHEN wli.IsDeleted = 1 THEN 0 ELSE 1 END) ActiveWatchlist
	  ,NULL ActiveCopy
  FROM [DWH_watchlists].[Fact_WatchlistsItems] wli WITH (NOLOCK)
  INNER JOIN  [DWH_watchlists].[Fact_Watchlists] wl WITH (NOLOCK)
  ON wli.WatchlistId = wl.WatchlistId
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON wl.CID = dc.RealCID
  INNER JOIN #man m
  ON dc.AccountManagerID = m.ManagerID
  LEFT JOIN [DWH_dbo].[Dim_Customer] dc1 WITH (NOLOCK)
  ON wli.ItemId = dc1.RealCID
  WHERE wli.DateID >=20200101
and wli.DateID <=20240114
  AND ItemId IN (14959563)
  AND dc.IsValidCustomer = 1
  GROUP BY wl.CID
	  ,dc1.UserName
	  ,AM
UNION all
SELECT  dm.CID
       ,AM
       ,dm.ParentUserName
	   ,NULL ActiveWatchlist
       ,CASE WHEN MAX(dm.IsActive) = 0 THEN 0 ELSE 1 END ActiveCopy
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dc.RealCID = dm.CID
INNER JOIN #man m
ON dc.AccountManagerID = m.ManagerID
WHERE dm.ParentCID IN (14959563)--,14959563
and OpenDateID <=202401014
AND dc.IsValidCustomer = 1
GROUP BY dm.CID
       ,dm.ParentUserName
	   ,AM
)q0
GROUP BY q0.CID
	  ,q0.UserName
	  ,q0.AM
)q1
FULL OUTER JOIN 
(SELECT CID
      ,m.AM
      ,1 Is20PercBalance
FROM #vl vl WITH (NOLOCK)
  INNER JOIN #man m
  ON vl.AccountManagerID = m.ManagerID
WHERE (1.0*vl.Credit)/vl.RealizedEquity >=0.2
AND RealizedEquity>10000
AND vl.IsCredit = 1
)q2
ON q2.CID = q1.CID
LEFT JOIN #vl vl WITH (NOLOCK)
ON COALESCE(q1.CID,q2.CID) = vl.CID
LEFT JOIN #equityCopy c 
ON q1.CID = c.CID
GROUP BY COALESCE(q1.CID,q2.CID)
      ,COALESCE(q1.AM,q2.AM)
	  ,ISNULL(q1.UserName,'Aukie2008')