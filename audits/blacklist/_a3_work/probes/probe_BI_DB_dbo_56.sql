SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_NonUS_Logins' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_NonUS_Logins] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_NOP_Distribution_Crypto' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_NOP_Distribution_Crypto] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Operations_Monthly_KPIs_Affiliates' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Operations_Monthly_KPIs_Cashouts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Cashouts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Operations_Monthly_KPIs_Verifications' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Verifications]

