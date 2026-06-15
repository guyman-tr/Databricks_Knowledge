SELECT [Region]
      ,dpl.PlayerLevelID
      ,CAST(CONVERT(CHAR(8),EOMONTH([Date]),112) AS INT) Date
      ,[KPI]
  FROM [BI_DB].[dbo].[BI_DB_ClubRegionsKPI]
  INNER JOIN DWH.dbo.Dim_PlayerLevel dpl
  ON dpl.Name = [Club]
  WHERE Region = 'All'