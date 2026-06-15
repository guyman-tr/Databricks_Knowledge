SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Index_Dividend_TaxReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Index_Dividend_TaxReport_CID_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport_CID_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_IndexDividends_Alert' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_IndexDividends_Alert] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Instrument_Overview' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Instrument_Overview] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Instruments_BidAndAsk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Instruments_BidAndAsk]

