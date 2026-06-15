SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Operations_Monthly_KPIs_Wires' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Wires] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Operations_Onboarding_Flow_UserKPIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_Fraud_Alert_Analysis' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_Fraud_Alert_Analysis] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_HighCompensationsVsDeposits' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_HighCompensationsVsDeposits] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_OPS_KYC_Verification' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_OPS_KYC_Verification]

