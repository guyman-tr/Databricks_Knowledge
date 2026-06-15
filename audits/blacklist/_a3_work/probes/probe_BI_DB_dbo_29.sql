SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_ThisMonth' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisMonth] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_ThisYear' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_ThisYear] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_Yesterday' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Yesterday] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCopyRevenue' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCopyRevenue] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyGain_History' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyGain_History]

