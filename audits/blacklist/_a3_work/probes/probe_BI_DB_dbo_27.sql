SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Daily_AffiliatesPaidAndCashout' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Daily_AffiliatesPaidAndCashout] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Daily_CID_Dividend_TaxReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Daily_CID_Dividend_TaxReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Daily_HighCashoutEmailsForManagement' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Daily_HighCashoutEmailsForManagement] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Daily_Open_Closed_Position' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Daily_Open_Closed_Position] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Daily_TradeData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Daily_TradeData]

