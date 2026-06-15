SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Market_Manipulation_OutstandingsharesHigherthan005' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Market_Manipulation_OutstandingsharesHigherthan005] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Market_Manipulation_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Market_Manipulation_Report] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MarketMakerAllTrade' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MarketMakerAllTrade] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MarketMakerAllTradeEtoroX' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MarketMakerAllTradeEtoroX]

