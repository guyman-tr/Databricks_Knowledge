SELECT cls.CID
			 ,cls.ClusterDetail
			 ,cls.ClusterSF
			 ,cls.FromDateID
			 ,cls.ToDateID
FROM BI_DB.dbo.BI_DB_CID_DailyCluster cls WITH (NOLOCK)