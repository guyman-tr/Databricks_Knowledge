SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IGReconTrades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IGReconTrades] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IndiciesIntraHour_Clients' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IndiciesIntraHour_Clients] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_IndiciesIntraHour_Etoro' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_IndiciesIntraHour_Etoro] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Islamic_Daily_Administrative_Fee' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Islamic_Daily_Spot_Price_Adjustment' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Islamic_Daily_Spot_Price_Adjustment]

