SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_Agg_daily_Staking' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_Agg_daily_Staking] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_EU_Custody' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_EU_Custody] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_EU_Custody_Instrument_Agg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_EU_Custody_Instrument_Agg] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_UK_Custody' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_UK_Custody] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_UK_Custody_Resolver' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_UK_Custody_Resolver]

