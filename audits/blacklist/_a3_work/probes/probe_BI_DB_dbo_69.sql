SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Staking_Email_For_Marcin' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Staking_Email_For_Marcin] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Staking_Platform_Compensations' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Staking_Platform_Compensations] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_STDSnapshots' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_STDSnapshots] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Stocks_HS121_CIDs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Stocks_HS121_CIDs] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Stocks_HS125' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Stocks_HS125]

