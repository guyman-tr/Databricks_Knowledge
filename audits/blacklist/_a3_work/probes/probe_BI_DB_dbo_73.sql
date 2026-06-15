SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Transactions_Per_Time_Unit' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Transactions_Per_Time_Unit] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Twitter' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Twitter] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_UK_CommissionReport_byLeverage' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_UK_CommissionReport_byLeverage] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Unsettled_Trades_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Unsettled_Trades_Risk] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Address_Change' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Address_Change]

