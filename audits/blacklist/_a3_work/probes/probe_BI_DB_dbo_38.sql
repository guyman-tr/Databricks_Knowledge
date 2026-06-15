SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Fact_Customer_Action_Position_Distribution' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Fact_Customer_Action_Position_Distribution] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Failed_Verification_MA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Failed_Verification_MA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FB_Conversion' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FB_Conversion] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FB_Performance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FB_Performance] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FB_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FB_Report]

