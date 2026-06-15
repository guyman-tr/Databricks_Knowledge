SELECT 'Dealing_dbo' AS schema_name, 'Dealing_DailySpread_ModeFrequency' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_DailySpread_ModeFrequency] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_DailyVariableSpread' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_DailyVariableSpread] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_DailyZeroPnL_Stocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_DailyZeroPnL_Stocks] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_DealingDashboard_Clients' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_DealingDashboard_Clients] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Duco_ActivityRecon' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Duco_ActivityRecon]

