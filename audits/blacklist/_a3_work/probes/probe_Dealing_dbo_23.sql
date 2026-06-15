SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SAXORecon_EODHoldings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SAXORecon_EODHoldings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SaxoRecon_FXnCommed_EODHoldings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SaxoRecon_FXnCommed_EODHoldings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SAXORecon_Trades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SAXORecon_Trades] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_SpreadsMST' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_SpreadsMST] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Staking_Club_US' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Staking_Club_US]

