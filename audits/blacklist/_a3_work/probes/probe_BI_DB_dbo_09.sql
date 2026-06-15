SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PlayerStatus_Changes' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PlayerStatus_Changes] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_SAR_Report_FCA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_SAR_Report_FCA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_Singapore_Risk_Classification' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_Singapore_Risk_Classification] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_SubEntity_Categorization' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_SubEntity_Categorization] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AMLPeriodicReview' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview]

