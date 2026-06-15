SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W_Tue_Email_for_KYT' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W_Tue_Email_for_KYT] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W_Wed_Compliance_Vulnerability_ALL' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W_Wed_Compliance_Vulnerability_ALL] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_W8_Users_Status' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_W8_Users_Status] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Watchlist_Tracking_High_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Watchlist_Tracking_High_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Watchlist_Tracking_Item_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Watchlist_Tracking_Item_Level]

