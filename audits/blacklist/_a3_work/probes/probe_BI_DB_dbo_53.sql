SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_M_SB_Fiktive_Table' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_M_SB_Fiktive_Table] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_MarketingCloudDaily' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_MarketingCloudDaily] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_MarketingDailyRawData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_MarketingDailyRawData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_MarketingMonthlyRawData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_MarketingMonthlyRawData] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_MifidAccountType_Count' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_MifidAccountType_Count]

