SELECT dc1.Name Country
	  ,dpl.Name Level
	  ,dl.Name Language
	  ,dc1.MarketingRegionManualName  Region
	  ,COUNT(1) Users
	  ,MAX(cp.UpdateDate) LastUpdate
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON CID = dc.RealCID
INNER JOIN DWH_dbo.Dim_Language dl WITH (NOLOCK)
ON dc.LanguageID = dl.LanguageID
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON cp.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON CASE WHEN cp.IsDowngrade = 1 THEN cp.LastTier ELSE  cp.CurrentTier END = dpl.PlayerLevelID
WHERE CASE WHEN cp.IsDowngrade = 1 THEN cp.LastTier ELSE  cp.CurrentTier END != 1
and DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club])
GROUP BY dc1.Name 
	  ,dpl.Name 
	  ,dl.Name
	  ,dc1.MarketingRegionManualName