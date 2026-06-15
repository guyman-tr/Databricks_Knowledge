SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CloseOnly_Recon' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CloseOnly_Recon] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CME_Reporting' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CME_Reporting] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Commission_Assurance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Commission_Assurance] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Commission_Assurance_By_Position' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Commission_Assurance_By_Position] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CommoditiesIntraHour_Clients' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CommoditiesIntraHour_Clients]

