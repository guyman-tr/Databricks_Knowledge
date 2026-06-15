SELECT 'Dealing_dbo' AS schema_name, 'Dealing_BNY_VIRTU_ReconEODHolding' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_BNY_VIRTU_ReconEODHolding] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_BNY_VIRTU_ReconTrades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_BNY_VIRTU_ReconTrades] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CapitalGuarantee' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CapitalGuarantee] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEP_ExecutionMonitoring' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEP_ExecutionMonitoring] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CEPDailyAudit_Conditions' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CEPDailyAudit_Conditions]

