SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_FinraGap' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_FinraGap] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_LiabilityDecomp' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_LiabilityDecomp] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_CO_Cluster_Daily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_CO_Cluster_Daily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Compensation_Activity_Data_CompensationReason' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_CompensationReason]

