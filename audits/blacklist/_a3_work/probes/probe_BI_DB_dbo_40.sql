SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Net_MIMO' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Net_MIMO] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Non_US_Settlement_New_2023' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2023] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Non_US_Settlement_New_2025' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2025] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Panel_Reports_New' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Panel_Reports_New]

