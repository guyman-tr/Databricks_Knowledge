SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Duco_EODRecon' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Duco_EODRecon] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Employee_Zero_StocksETFs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Employee_Zero_StocksETFs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Employees_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Employees_Report] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_EquityFees' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_EquityFees] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ESMANetLoss' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ESMANetLoss]

