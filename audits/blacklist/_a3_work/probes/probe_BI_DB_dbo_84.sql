SELECT 'BI_DB_dbo' AS schema_name, 'DWH_CIDsDailyRisk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[DWH_CIDsDailyRisk] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'DWH_GainDaily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[DWH_GainDaily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'External_Price_History_LastPriceBeforeClose_Range' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[External_Price_History_LastPriceBeforeClose_Range] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'IR_Dashboard_Monitor_Checks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[IR_Dashboard_Monitor_Checks] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'LTV_FromDB_ToBigQuery' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[LTV_FromDB_ToBigQuery]

