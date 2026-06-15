SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_FID_Copy_Side' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_FID_Copy_Side] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_FID_PI_Side' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_FID_PI_Side] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_FID_Same_as_pi' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_FID_Same_as_pi] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_FID_Same_Copy' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_FID_Same_Copy] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_SameIP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_SameIP]

