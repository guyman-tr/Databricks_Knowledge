SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_USA_FinanceReport_forTax' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_USA_FinanceReport_forTax] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_USA_FinanceReport_forTax_CreditID' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_USA_FinanceReport_forTax_CreditID] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_UsageTracking_SF' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_UsageTracking_SF] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_User_Segment_Snapshot' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_User_Segment_Snapshot] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_UsersEngagement' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_UsersEngagement]

