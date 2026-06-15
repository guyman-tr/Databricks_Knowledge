SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Investors' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Investors] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Investors_Top10' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Investors_Top10] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Investors_Unclustered' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InvestorsDetail' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InvestorsDetail] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_InvestorsKPI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_InvestorsKPI]

