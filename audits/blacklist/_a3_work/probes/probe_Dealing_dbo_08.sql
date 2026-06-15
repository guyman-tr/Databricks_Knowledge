SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CommoditiesIntraHour_Etoro' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CommoditiesIntraHour_Etoro] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CopierAnalysis' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CopierAnalysis] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CopyPortfolio_Allocation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CopyPortfolio_Allocation] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_CryptoVolume_ByDirection' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_CryptoVolume_ByDirection] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_DailyAvgSpread' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_DailyAvgSpread]

