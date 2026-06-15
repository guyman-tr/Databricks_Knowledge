SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Crypto_Active_Open_Churn_Winback' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Crypto_Active_Open_Churn_Winback] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Crypto_Airdrop' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Crypto_Airdrop] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Crypto_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Crypto_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CryptoDashboardNew' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CryptoDashboardNew] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CryptoMarketingList' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CryptoMarketingList]

