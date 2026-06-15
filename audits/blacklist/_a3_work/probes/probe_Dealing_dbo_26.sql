SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Summary' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Summary] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Summary_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Summary_US] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_WelcomeEmail_Temp' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_WelcomeEmail_Temp] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SuspiciousActivityTrading_24H' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SuspiciousActivityTrading_24H] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SuspiciousActivityTrading_24H_Email' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SuspiciousActivityTrading_24H_Email]

