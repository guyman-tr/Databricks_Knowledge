SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AffiliateFTDsAndURLS' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AffiliateFTDsAndURLS] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AffiliatePayment' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AffiliatePayment] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Affiliates_FraudMonitoring' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Affiliates_FraudMonitoring] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Affiliates_VerificationSLA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Affiliates_VerificationSLA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AffiliateScore' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AffiliateScore]

