SELECT 'Dealing_dbo' AS schema_name, 'Dealing_JP_Credit_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_JP_Credit_Risk] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Latency_SuspiciousCIDs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Latency_SuspiciousCIDs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_LP_StocksNOP' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_LP_StocksNOP] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ManipulationReport_RealStocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ManipulationReport_RealStocks] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_ManipulationReport_RealStocks_CID' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_ManipulationReport_RealStocks_CID]

