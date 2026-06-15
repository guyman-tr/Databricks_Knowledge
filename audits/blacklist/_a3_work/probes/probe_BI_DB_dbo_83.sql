SELECT 'BI_DB_dbo' AS schema_name, 'Compliance_BI_Leverage_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[Compliance_BI_Leverage_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'Crypto_Top_1000_List' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[Crypto_Top_1000_List] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'Dealing_CryptoRebate' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[Dealing_CryptoRebate] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'Dealing_Unrealized_CryptoRebate' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[Dealing_Unrealized_CryptoRebate] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'DWH_CIDs7DaysDeviation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[DWH_CIDs7DaysDeviation]

