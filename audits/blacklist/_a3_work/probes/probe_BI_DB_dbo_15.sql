SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CapitalGuarantee_Panel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Cashout_Performance_Monitoring' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Cashout_Performance_Monitoring] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CBZero_TreesizeZero_Alert' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CBZero_TreesizeZero_Alert] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ChargebackReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ChargebackReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_BalanceDays' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_BalanceDays]

