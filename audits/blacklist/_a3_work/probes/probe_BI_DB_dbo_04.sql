SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_BI_Alerts_New' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_BI_Alerts_New_Master_SubAccount' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New_Master_SubAccount] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_BI_Alerts_New_Singapore' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New_Singapore] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Documents_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Documents_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Documents_Request' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Documents_Request]

