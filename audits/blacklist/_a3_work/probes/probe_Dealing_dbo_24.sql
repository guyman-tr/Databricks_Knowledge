SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Compensation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Compensation] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Compensation_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Compensation_US] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_DailyPool' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_DailyPool] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_DailyPool_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_DailyPool_US] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Emails' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Emails]

