SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PDT' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PDT] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PlayerLevel_Data' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PlayerLevel_Data] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PlayerLevel_Data_PIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PlayerLevel_Data_PIs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PlayerLevel_Fails' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PlayerLevel_Fails] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PlayerLevel_Fails_PIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PlayerLevel_Fails_PIs]

