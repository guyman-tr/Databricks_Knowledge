SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_MIMO_Trading_Platform' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_Trading_Platform] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_Non_Revenue_Generating_Actions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_Non_Revenue_Generating_Actions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_PnL' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_PnL] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_Revenue_Generating_Actions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_Revenue_Generating_Actions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_DDR_Fact_Trading_Volumes_And_Amounts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_DDR_Fact_Trading_Volumes_And_Amounts]

