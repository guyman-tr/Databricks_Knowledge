SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InstrumentsAlerts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InstrumentsAlerts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InterestDaily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InterestDaily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InterestMonthly' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InterestMonthly] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Investment_Monthly_Data' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Investment_Monthly_Data] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Investment_PIMeetup' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Investment_PIMeetup]

