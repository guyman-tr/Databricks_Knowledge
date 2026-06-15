SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_Score_CID_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_Score_CID_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LargeCashoutReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LargeCashoutReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LimitedAccountsWithReasons' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasons] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LimitedAccountsWithReasonsNEW' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasonsNEW] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LiveAcquisitionDashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard]

