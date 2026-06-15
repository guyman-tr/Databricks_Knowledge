SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Stocks_Opportunities' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Stocks_Opportunities] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_StocksETFs_SignificantAllocation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_StocksETFs_SignificantAllocation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_STP_Redeems' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_STP_Redeems] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Subsidieries_Realized_Commissions_Adjustments' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Subsidieries_Realized_Commissions_Adjustments] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_SuspiciousActivityTrading_Investing' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_SuspiciousActivityTrading_Investing]

