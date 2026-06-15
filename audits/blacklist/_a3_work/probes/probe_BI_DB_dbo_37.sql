SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_EOMExposures' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_EOMExposures] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_EquitySnapshots' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_EquitySnapshots] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_eTorian_NetProfit' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_eTorian_NetProfit] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_eTorian_PnL' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_eTorian_PnL]

