SELECT dcl.CID,dcl.ClusterDetail 
FROM [BI_DB_dbo].[BI_DB_CID_DailyCluster] dcl
WHERE CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT) BETWEEN dcl.FromDateID AND dcl.ToDateID