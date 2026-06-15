SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PI_Affiliate' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PI_Affiliate] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PI_Gain' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PI_Gain] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PI_StatusPanel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PI_StatusPanel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PLTV' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PLTV] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionHoldingTime' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionHoldingTime]

