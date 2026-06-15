SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_Reports_Status' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_Reports_Status] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Technical_Issues_Compensation_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Technical_Issues_Compensation_Risk] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_TIN_Gap' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_TIN_Gap] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_TIN_Gap_Temp_pop' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_TIN_Gap_Temp_pop] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Trading_Failures_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Trading_Failures_Risk]

