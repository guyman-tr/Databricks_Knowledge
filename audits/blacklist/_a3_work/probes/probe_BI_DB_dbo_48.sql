SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_DOBover85' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_DOBover85] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_eToroMoney_UpgradedClubMembers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_eToroMoney_UpgradedClubMembers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_Knowledge_Assessment' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_Knowledge_Assessment] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_Panel' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_Panel] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_KYC_Questions_Answers_Row_Data' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data]

