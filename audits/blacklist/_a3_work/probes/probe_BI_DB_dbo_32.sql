SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_AUM' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_AUM] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_MIMO_AllPlatforms' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_MIMO_eMoney_Platform' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_eMoney_Platform] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_MIMO_Options_Platform' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_Options_Platform]

