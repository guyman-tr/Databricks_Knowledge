SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LiveAcquisitionDashboard_Daily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LiveAcquisitionDashboard_Daily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Local_Currencies_MIMO' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Local_Currencies_MIMO] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LTV_BI_Actual' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LTV_BI_Actual_Daily_Snapshot' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual_Daily_Snapshot] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LTV_By_FTD_MOP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LTV_By_FTD_MOP]

