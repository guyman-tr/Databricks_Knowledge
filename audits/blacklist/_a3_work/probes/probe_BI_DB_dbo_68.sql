SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_rsk_Portfolio' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_rsk_Portfolio] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_rsk_Risk_PI_Correl' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_rsk_Risk_PI_Correl] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_rsk_Risk_PI_Stats' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_rsk_Risk_PI_Stats] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Scored_Appropriateness_Negative_Market' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Scored_Appropriateness_Negative_Market] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Snapshot_CID_LifeStageDefinition' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Snapshot_CID_LifeStageDefinition]

