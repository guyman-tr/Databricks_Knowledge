SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Emails_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Emails_US] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Position' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Position] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Position_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Position_US] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Results' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Results] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Results_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Results_US]

