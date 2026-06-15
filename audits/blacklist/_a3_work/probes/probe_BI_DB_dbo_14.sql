SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_BuyTax_Fix' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_BuyTax_Fix] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Capital_Adequacy_Daily_Equity' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_Equity] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Capital_Adequacy_Daily_NOP_KASA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_NOP_KASA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Capital_Adequacy_Monthly_NOP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Capital_Guarantee' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Capital_Guarantee]

