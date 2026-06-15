SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopyBlockedAUM' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUM] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopyBlockedAUMHistory' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUMHistory] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopycatsOfCopyfunds' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopycatsOfCopyfunds] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopyDailyData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopyDailyData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CopyFund_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CopyFund_Positions]

