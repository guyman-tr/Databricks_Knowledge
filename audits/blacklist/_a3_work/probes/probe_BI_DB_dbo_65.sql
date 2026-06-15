SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Reg_UK_Compliance_KYC_Weekly_Export' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_KYC_Weekly_Export] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Reg_UK_Compliance_Professional_OptUp' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_Professional_OptUp] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Reg_UK_Compliance_VolumeByInstrument' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_VolumeByInstrument] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Regulation_Change_Abuse_Categories' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Regulation_Change_Abuse_Categories] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Regulation_Change_Abuse_CIDs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Regulation_Change_Abuse_CIDs]

