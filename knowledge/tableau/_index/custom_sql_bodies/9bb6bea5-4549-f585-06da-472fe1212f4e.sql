SELECT DISTINCT dm.CID 
                ,dm.ParentCID
                ,ISNULL(p.UserName,' ') UserName
				,MAX(dm.IsActive) IsActive
				,NULL ActiveWatchlist
                ,campaign_name 
FROM DWH_dbo.Dim_Mirror dm
JOIN DWH_dbo.Dim_Customer dc
ON dc.RealCID = dm.CID
Join #PI p
ON dm.ParentCID = p.CID
GROUP BY dm.CID 
          ,dm.ParentCID
          ,p.UserName
,campaign_name 
UNION ALL
SELECT DISTINCT wl.CID
		,wli.ItemId
                ,ISNULL(p.UserName,' ') UserName
				,NULL ActiveCopy
                ,MAX(CASE WHEN wli.IsDeleted = 1 THEN 0 ELSE 1 END) ActiveWatchlist
                ,p.campaign_name 

  FROM [DWH_watchlists].[Fact_WatchlistsItems] wli WITH (NOLOCK)
  INNER JOIN  [DWH_watchlists].[Fact_Watchlists] wl WITH (NOLOCK)
  ON wli.WatchlistId = wl.WatchlistId
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON wl.CID = dc.RealCID
JOIN #PI p
ON ItemId = p.CID
  WHERE wli.DateFrom >=start_date
and wli.DateFrom <=end_date
  GROUP BY wl.CID
	  ,wli.ItemId
,p.UserName
,p.campaign_name