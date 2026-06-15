SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ClusteringDailyPrepData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ClusteringDailyPrepData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_ClientBalance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_ClientBalance] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_CycleGap' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_CycleGap] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_EU_Outliers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_EU_Outliers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_Finra_NonCash_Comps' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_Finra_NonCash_Comps]

