SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Flare_Eligibility' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Flare_Eligibility] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FSRA_Weekly_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FSRA_Weekly_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Futures_Finance_Prep_Data' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Futures_Finance_Prep_Data] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_German_Crypto_Transition_To_Tangany' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_German_Crypto_Transition_To_Tangany] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_German_Open_Real_Crypto_Positions_Daily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_German_Open_Real_Crypto_Positions_Daily]

