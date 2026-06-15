SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_HourlyReport_Withdraws' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_HourlyReport_Withdraws] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ICF_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ICF_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_IFRS_15_Daily_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_IFRS_15_Daily_Positions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_IFRS15_Daily_Balance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_IFRS15_Daily_Balance] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InactivityFees' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InactivityFees]

