SELECT 'Dealing_dbo' AS schema_name, 'Dealing_AbuseAPI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_AbuseAPI] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_AbusersCIDs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_AbusersCIDs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ApexRecon_Hedging' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ApexRecon_Hedging] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ApexRecon_Holdings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ApexRecon_Holdings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ApexRecon_TradeActivity' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ApexRecon_TradeActivity]

