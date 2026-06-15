SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CustomerCross' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CustomerCross] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CustomerCross_New' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CustomerCross_New] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CustomerFirst5OpenPositions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CustomerFirst5OpenPositions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CySEC_Submission_ICF' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CySEC_Submission_ICF] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_D_HighRedeemsApprovalForManagement' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_D_HighRedeemsApprovalForManagement]

