SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AllDeposits' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AllDeposits] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AM_Contacted' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AM_Contacted] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AM_Portfolio_Summary' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AM_Portfolio_Summary] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_ASIC_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_ASIC_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_BI_Alerts_MultipleAccountseMoney' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_MultipleAccountseMoney]

