SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Real_Futures_Custody_And_Transfers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Real_Futures_Custody_And_Transfers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Staking_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Staking_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_First5Actions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_First5Actions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FirstTimeRev10' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FirstTimeRev10] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FirstTimeRev5' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FirstTimeRev5]

