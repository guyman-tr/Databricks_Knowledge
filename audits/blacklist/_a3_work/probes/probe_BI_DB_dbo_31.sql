SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_CID_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_CID_Level_Auxiliary_Metrics' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level_Auxiliary_Metrics] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Customer_Daily_Status' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Customer_Daily_Status] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Customer_Periodic_Status' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Customer_Periodic_Status] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Daily_Aggregated' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Daily_Aggregated]

