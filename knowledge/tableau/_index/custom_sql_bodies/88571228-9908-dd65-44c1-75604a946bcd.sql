SELECT vl.CID
	,ISNULL(vl.Liabilities,0) + ISNULL(vl.ActualNWA,0) Equity
	,ISNULL(cp.EquityCopy,0) EquityCopy
	,vl.RealizedEquity
	,Credit Balance
        ,cp.ParentCID
        ,cp.UserName
        ,campaign_name
  FROM DWH_dbo.V_Liabilities vl WITH (NOLOCK)
  INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON vl.CID = dc.RealCID
  INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
  ON dc.PlayerLevelID = dpl.PlayerLevelID
  LEFT JOIN  ( SELECT ghgc.CID
        ,ISNULL(ghgc.Cash,0) + ISNULL(ghgc.Investment,0) +  ISNULL(ghgc.PnL,0) EquityCopy
        ,ParentCID
        ,p.UserName
        ,campaign_name
  FROM general.etoroGeneral_History_GuruCopiers ghgc
  JOIN #PI p
  ON p.CID = ParentCID
  WHERE  ghgc.partition_date = CAST(getdate() AS DATE))cp
  ON vl.CID = cp.CID
  WHERE vl.DateID = CAST(CONVERT(CHAR(8),getdate()-1,112) AS INT)