SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ReverseCoReport' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ReverseCoReport] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RiskAlertManagementTool' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RiskAlertManagementTool] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RiskPayPalDepositors' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RiskPayPalDepositors] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_RollOverFee_ByInstrument' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_RollOverFee_ByInstrument] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_rsk_DailyRiskAgg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_rsk_DailyRiskAgg]

