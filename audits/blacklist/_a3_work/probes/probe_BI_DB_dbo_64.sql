SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_QMMF_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_QMMF_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_QMMF_Report_Finance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_QMMF_Report_Finance] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_QTFN_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_QTFN_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RAF_Invitees_KPIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RAF_Invitees_KPIs] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RecurringInvestment_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RecurringInvestment_Positions]

