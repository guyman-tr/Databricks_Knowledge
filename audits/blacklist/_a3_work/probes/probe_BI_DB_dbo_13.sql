SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Bing_PBI_Goals_Funnels' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Goals_Funnels] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Bing_PBI_Group_Dict' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Bing_PBI_Group_Dict] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Blocked_Customers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Blocked_Customers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_BO_Generated_Compensations' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_BO_Generated_Compensations] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_BODailyCompensations' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_BODailyCompensations]

