SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Negative_Balance_Monitor_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Negative_Balance_Monitor_Risk] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Negative_Market_Monthly_Aggregated' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Negative_Market_Monthly_Aggregated] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_NewBonusReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_NewBonusReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_NewContactsActivityPerRep' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_NewContactsActivityPerRep] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_NonPI_HighAUM' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_NonPI_HighAUM]

