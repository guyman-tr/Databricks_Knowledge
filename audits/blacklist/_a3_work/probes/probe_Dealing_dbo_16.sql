SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Manual_Exec_Trade' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Manual_Exec_Trade] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Manual_Exec_Trade_Summary' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Manual_Exec_Trade_Summary] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ManualPositionClose' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ManualPositionClose] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Marex_Recon_EODHoldings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Marex_Recon_EODHoldings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Marex_Recon_EODHoldings_Futures' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Marex_Recon_EODHoldings_Futures]

