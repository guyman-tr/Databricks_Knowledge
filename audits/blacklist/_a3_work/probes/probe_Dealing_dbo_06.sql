SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientDataRecurring' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientDataRecurring] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientDataTop50' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientDataTop50] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientsCapitalAdequacy' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientsCapitalAdequacy] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientsDataChange_3Months' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientsDataChange_3Months] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ClientsDataChange_6Months' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ClientsDataChange_6Months]

