SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_Rules' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_Rules] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_Conditions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_Conditions] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_ConditionToCP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_ConditionToCP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_CP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_CP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPWeeklyAudit_CPToRule' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPWeeklyAudit_CPToRule]

