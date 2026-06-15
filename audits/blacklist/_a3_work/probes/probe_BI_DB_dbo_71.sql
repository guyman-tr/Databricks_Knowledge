SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_1099_PartA' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_1099_PartA] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_1099_PartB' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_1099_PartB] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_Compensation_for_1099' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_Compensation_for_1099] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_Compliance_TIN' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_Compliance_TIN] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Tax_Compliance_Trade_CFD_US_Stocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Tax_Compliance_Trade_CFD_US_Stocks]

