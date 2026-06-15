SELECT pan.CID, pan.FTD_Month, pan.FirstAction, pan.Country, fd.Manager, fd.Club, pan.Active_Month RevenueMonth
      ,[Revenue_Total], fd.RealizedEquity, dcl.ClusterDetail
     
  FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] pan WITH (NOLOCK)
  LEFT JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK) ON fd.CID = pan.CID
  LEFT JOIN [BI_DB].[dbo].[BI_DB_CID_DailyCluster] dcl WITH (NOLOCK) ON pan.CID = dcl.CID AND dcl.IsLastCluster = 1
  WHERE pan.ActiveDate >= DATEADD(MONTH, -4, GETDATE()) AND [Revenue_Total] >= 10