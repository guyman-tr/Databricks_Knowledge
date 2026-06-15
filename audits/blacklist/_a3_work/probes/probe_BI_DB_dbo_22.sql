SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Restriction_Lists_Forbidden_Trading' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Forbidden_Trading] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Surveillance_ShortTermTrades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Surveillance_ShortTermTrades] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Surveillance_Snapshot' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Surveillance_Snapshot] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_VP_Monthly_MI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_VP_Monthly_MI]

