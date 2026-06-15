SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DepositUsersFirstTouchPoints' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DepositUsersFirstTouchPoints] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Diversification' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Diversification] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DLT_Tangany_Trades_Netting' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DLT_Tangany_Trades_Netting] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Document_Vendors' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Document_Vendors] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Dummy' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Dummy]

