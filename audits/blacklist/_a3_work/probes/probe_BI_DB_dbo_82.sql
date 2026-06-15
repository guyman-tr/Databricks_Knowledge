SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_WatchListsByFunnel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_WatchListsByFunnel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_WeeklyCopyBlock' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_WeeklyCopyBlock] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Wire_PIP_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Wire_PIP_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_YearlyGain' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_YearlyGain] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'Client_Balance_Breakdown_Instrument_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[Client_Balance_Breakdown_Instrument_Level]

