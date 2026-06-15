SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MarketMakerBoundaries_CFD' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MarketMakerBoundaries_CFD] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MarketMakerBoundaries_Real' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MarketMakerBoundaries_Real] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Max_NOP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Max_NOP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MAXLeverageByNOP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MAXLeverageByNOP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_MaxNOPLimitSettings' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_MaxNOPLimitSettings]

