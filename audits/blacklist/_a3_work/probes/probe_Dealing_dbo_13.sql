SELECT 'Dealing_dbo' AS schema_name, 'Dealing_HedgeCost' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_HedgeCost] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Holdings_RealStocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Holdings_RealStocks] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IBRecon_EODHoldings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IBRecon_EODHoldings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IBRecon_Trades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IBRecon_Trades] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IGReconEODHolding' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IGReconEODHolding]

