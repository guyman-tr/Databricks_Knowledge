SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Unrealized_Open_CryptoRebate' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Unrealized_Open_CryptoRebate] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_US_Stocks_SmartPortfolio' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_US_Stocks_SmartPortfolio] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_VisionRecon_EODHoldings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_VisionRecon_EODHoldings] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_VisionRecon_Trades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_VisionRecon_Trades] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'DSC_HedgeOnIndices' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[DSC_HedgeOnIndices]

