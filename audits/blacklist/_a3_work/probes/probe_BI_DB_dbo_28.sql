SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_Instrument_Agg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Instrument_Agg] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_Last2weeks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_Last2weeks] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_LastYear' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_LastYear] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DailyCommisionReport_MonthlyData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport_MonthlyData]

