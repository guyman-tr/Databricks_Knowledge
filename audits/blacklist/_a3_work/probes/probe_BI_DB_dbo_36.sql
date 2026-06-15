SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Employee_Crypto_NWA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Employee_Crypto_NWA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Employees_Program' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Employees_Program] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_EndOfDayReport_Cashouts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_EndOfDayReport_Cashouts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_EndOfDayReport_Redeems' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_EndOfDayReport_Redeems] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_EOD_USD_cr' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_EOD_USD_cr]

