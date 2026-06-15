SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CIDs_CommissionsAndFails_PIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CIDs_CommissionsAndFails_PIs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Clicks_OpenClose_Breakdown' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Clicks_OpenClose_Breakdown] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientCountry' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientCountry] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientCountry_Reg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientCountry_Reg] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientDataFinal' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientDataFinal]

