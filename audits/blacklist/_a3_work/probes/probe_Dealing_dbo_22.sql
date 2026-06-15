SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PreviouslyIdentifiedAbusers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PreviouslyIdentifiedAbusers] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PreviouslyIdentifiedAbusers_Email' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PreviouslyIdentifiedAbusers_Email] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_PriceLocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_PriceLocks] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Rollover_Assurance' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Rollover_Assurance] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_RolloverCommissionSplit' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_RolloverCommissionSplit]

