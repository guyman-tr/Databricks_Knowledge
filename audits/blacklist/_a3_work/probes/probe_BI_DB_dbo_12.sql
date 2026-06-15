SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AssignmentToolTasks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AssignmentToolTasks] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AssignmentToolVolumes' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AssignmentToolVolumes] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AvgHoldingTime' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AvgHoldingTime] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Bing_PBI_Campaign_Dict' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Campaign_Dict] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Bing_PBI_Daily_Perf' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Daily_Perf]

