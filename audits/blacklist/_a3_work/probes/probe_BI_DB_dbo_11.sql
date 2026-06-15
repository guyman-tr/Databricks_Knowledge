SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ASIC_GAML_Invested_Amount' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ASIC_GAML_Invested_Amount] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ASIC_Monitoring_CFD_W_Sun' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ASIC_Monitoring_CFD_W_Sun] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ASIC_Monthly_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ASIC_Monthly_Positions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AssignmentToolBacklog' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AssignmentToolBacklog] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AssignmentToolSLAs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AssignmentToolSLAs]

