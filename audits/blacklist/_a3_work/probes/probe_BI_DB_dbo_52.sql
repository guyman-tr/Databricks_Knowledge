SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_AML_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_AML_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_AML_Report_AGG' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_AML_Report_AGG] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_LifeStage_Matrix' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_LifeStage_Matrix]

