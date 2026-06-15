SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_KYC_SOF' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Periodic_Review_AR' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_AR] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Periodic_Review_HR' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_HR] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Periodic_Review_MR' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_MR] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse]

