SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_Daily_AcquisitionFunnel_VBT' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_Daily_AcquisitionFunnel_VBT] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_DailyCluster' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_DailyCluster] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_DailyPanel_Club' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_DailyPanel_FullData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_LifeStageDefinition' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_LifeStageDefinition]

