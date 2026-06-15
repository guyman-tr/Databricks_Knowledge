SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LTV_Predictions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LTV_Predictions] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_LTV_Revenue_Multipliers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_Affiliates_FraudMonitoring_Relations' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_Affiliates_FraudMonitoring_Relations] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_AML_Account_Closed' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_AML_Account_Closed] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_AML_Finance_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_AML_Finance_Report]

