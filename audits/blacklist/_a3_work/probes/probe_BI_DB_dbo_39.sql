SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_FCA_Liabilities' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_FCA_Liabilities] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_ASIC_MP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_ASIC_MP] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Audit_Auxillary_Datapoints' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Audit_Auxillary_Datapoints] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_Cashout_RollbackDetails' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_Cashout_RollbackDetails] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Finance_eToro_vs_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Finance_eToro_vs_Positions]

