SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Q_AML_EDD_US_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Q_AML_EDD_US_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Q_AML_FSA_Report_end' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Q_AML_FSA_Report_end] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Q_AML_FSA_Report_end_Market_Value' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Q_AML_FSA_Report_end_Market_Value] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Q_AML_FSA_Report_end_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Q_AML_FSA_Report_end_Positions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Q_AML_FSA_Report_start' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Q_AML_FSA_Report_start]

