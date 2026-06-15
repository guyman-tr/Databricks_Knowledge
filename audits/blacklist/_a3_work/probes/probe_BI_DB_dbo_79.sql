SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_VAT_Transactions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_VAT_Transactions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_VerificationStatus' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_VerificationStatus] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_VerificationStatus30Days' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_VerificationStatus30Days] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Vulnerability_CanceledWithdrawals' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Vulnerability_CanceledWithdrawals] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Vulnerability_LifetimeMetrics' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Vulnerability_LifetimeMetrics]

