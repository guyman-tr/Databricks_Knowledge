SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_ConditionToCP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_ConditionToCP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_CP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_CP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_CPToRule' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_CPToRule] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_ListCIDMapping' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_ListCIDMapping] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_NameLists' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_NameLists]

