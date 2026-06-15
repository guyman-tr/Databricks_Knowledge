SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Client_Balance_CID_Level_New_Blocked' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Client_Balance_CID_Level_New_Blocked] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ClientBalance_DDR_Data_Integrity_Alert' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ClientBalance_DDR_Data_Integrity_Alert] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ClubChangeLog' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ClubChangeLog] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ClubChangeLogProduct' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ClubChangeLogProduct] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ClubUsersDataRemarketingGoogle' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ClubUsersDataRemarketingGoogle]

