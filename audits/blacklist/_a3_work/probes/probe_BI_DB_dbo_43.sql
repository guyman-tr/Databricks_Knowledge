SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_GST_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_GST_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_H_SEA_CashoutsEstimation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_H_SEA_CashoutsEstimation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_High_Cashout_Emails_For_Management_Analysis' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_High_Cashout_Emails_For_Management_Analysis] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_HighCOsAndRedeemsWithSF' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_HighCOsAndRedeemsWithSF] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_HourlyReport_Redeems' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_HourlyReport_Redeems]

