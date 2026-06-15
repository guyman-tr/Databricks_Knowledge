SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_ListCIDMapping' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_ListCIDMapping] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_NameLists' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_NameLists] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_Rules' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_Rules] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CFDs_Stocks_Credit_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CFDs_Stocks_Credit_Risk] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CIDs_CommissionsAndFails' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CIDs_CommissionsAndFails]

