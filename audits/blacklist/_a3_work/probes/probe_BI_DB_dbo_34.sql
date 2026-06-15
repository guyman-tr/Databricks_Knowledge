SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Process_Monitor' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Process_Monitor] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_TimeRange_Aggregated_Country_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Demo_CID_Panel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Demo_CID_Panel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Depositors_By_Managers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Depositors_By_Managers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DepositSnapshots' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DepositSnapshots]

