SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Copyfunds_SignificantAllocation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Copyfunds_SignificantAllocation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopyMilestone' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopyMilestone] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Corporates_SummaryReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Corporates_SummaryReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Cross_Selling_Daily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Cross_Selling_Daily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Cross_Selling_Monthly' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Cross_Selling_Monthly]

