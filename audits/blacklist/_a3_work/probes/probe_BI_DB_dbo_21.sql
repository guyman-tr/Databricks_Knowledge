SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compensation_Activity_Data_Regulation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_Regulation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Clients_Dashboard_EOM_Pos' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Clients_Dashboard_EOM_Pos] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Illegal_Trades_Alerts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Illegal_Trades_Alerts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Restriction_Lists_CIDs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_CIDs] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compliance_Restriction_Lists_Countries' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_Countries]

