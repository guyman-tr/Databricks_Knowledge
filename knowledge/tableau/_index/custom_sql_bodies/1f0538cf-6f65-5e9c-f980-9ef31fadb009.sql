SELECT cls.CID
		,cls.ClusterDetail
		,cls.ClusterSF
		,cls.FromDateID
		,cls.ToDateID
		,cls.ClusterDynamic 
  FROM [BI_DB].[dbo].[BI_DB_CID_DailyCluster] cls WITH (NOLOCK)
 WHERE cls.IsSFCluster = 1