SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MaxPositionUnits' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MaxPositionUnits] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MCS_Model_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MCS_Model_Report] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MIMO_Zero' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MIMO_Zero] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Monitoring_ADV' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Monitoring_ADV] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Monitoring_ADV_MoreThanPercent' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Monitoring_ADV_MoreThanPercent]

