SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RejectedDocuments' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RejectedDocuments] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ReturnCalculation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ReturnCalculation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ReturnCalculation_Daily_Data' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ReturnCalculation_Daily_Data] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Revenue14DaysToBigQuery' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Revenue14DaysToBigQuery] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RevenueForum' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RevenueForum]

