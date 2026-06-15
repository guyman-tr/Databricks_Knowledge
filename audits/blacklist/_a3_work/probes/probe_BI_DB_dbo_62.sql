SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ProfessionalCustomers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ProfessionalCustomers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ProfessionalCustomersDocuments' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ProfessionalCustomersDocuments] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ProfessionalCustomersPending' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ProfessionalCustomersPending] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PTM_Levy_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PTM_Levy_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Publications' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Publications]

