SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_MultipleAccounts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_MultipleAccounts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_VerificationLevel2Stuck' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_VerificationLevel2Stuck] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_VerificationPipeline_OverLevel2' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_VerificationPipeline_OverLevel2] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Payoneer_Revenue_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Payoneer_Revenue_Report]

