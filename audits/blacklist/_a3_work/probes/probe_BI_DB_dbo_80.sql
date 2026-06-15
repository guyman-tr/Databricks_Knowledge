SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Vulnerability_Positions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Vulnerability_Positions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Vulnerable_Customers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Vulnerable_Customers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W_AML_PEP_Customers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W_AML_PEP_Customers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W_AML_PEP_Customers_Trun' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W_AML_PEP_Customers_Trun] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W_Mon_Compliance_CDIM_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W_Mon_Compliance_CDIM_Report]

