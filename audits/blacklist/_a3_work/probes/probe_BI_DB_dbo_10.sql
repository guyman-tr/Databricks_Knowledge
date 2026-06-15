SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AMLPeriodicReview_PostReview' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview_PostReview] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AppFlyer_Geo' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AppFlyer_Geo] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AppFlyer_Reports' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AppFlyer_Reports] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ApproperiatenessTest_FTP_CID_Level' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ApproperiatenessTest_FTP_CID_Level] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ASIC_CreditLine_At_transfer' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ASIC_CreditLine_At_transfer]

