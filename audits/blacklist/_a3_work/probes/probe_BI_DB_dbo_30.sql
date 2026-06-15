SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyNOP_ByInstrument' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyNOP_ByInstrument] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyPanel_Copy' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyPanel_Copy] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyRiskAlert' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyRiskAlert] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyTaboolaCombineAffwiz' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyTaboolaCombineAffwiz] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DCM_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DCM_Dashboard]

