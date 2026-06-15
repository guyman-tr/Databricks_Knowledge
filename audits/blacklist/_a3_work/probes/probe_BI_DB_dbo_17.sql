SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_MonthlyPanel_FullData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_VerificationLevel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_VerificationLevel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CID_WeeklyPanel_FullData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CID_WeeklyPanel_FullData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CIDFirstDates' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CIDFunnelFlow' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CIDFunnelFlow]

