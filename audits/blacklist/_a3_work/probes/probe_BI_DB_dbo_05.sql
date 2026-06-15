SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_FCA_Crypto_Threshold' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Gatsby_Alerts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Gatsby_Alerts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_High_Risk_Wallet' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_High_Risk_Wallet] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_IOB_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_IOB_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_KYC_Process' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_KYC_Process]

