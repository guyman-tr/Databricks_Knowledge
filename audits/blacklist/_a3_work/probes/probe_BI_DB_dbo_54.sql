SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Mirror_Assets_Allocation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Mirror_Assets_Allocation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Money_In_New_Management_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Money_In_New_Management_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Money_Out_New_Management_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Money_Out_New_Management_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Money_Out_STPAnalysis_OPS_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Money_Out_STPAnalysis_OPS_Dashboard] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Monthly_InterestPayment_Dashboard' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Monthly_InterestPayment_Dashboard]

