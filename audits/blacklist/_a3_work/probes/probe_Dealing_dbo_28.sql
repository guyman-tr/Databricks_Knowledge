SELECT 'Dealing_dbo' AS schema_name, 'DSC_HedgeOnIndices_H' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[DSC_HedgeOnIndices_H] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'StocksOverrideRateLog' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[StocksOverrideRateLog] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'V_Dealing_CEPDailyAudit_Conditions_Last180Days' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[V_Dealing_CEPDailyAudit_Conditions_Last180Days] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'V_Dealing_CEPDailyAudit_CP_Last180Days' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[V_Dealing_CEPDailyAudit_CP_Last180Days] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'V_Dealing_CEPDailyAudit_Rules_Last180Days' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[V_Dealing_CEPDailyAudit_Rules_Last180Days]

