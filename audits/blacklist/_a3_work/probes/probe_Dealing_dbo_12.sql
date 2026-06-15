SELECT 'Dealing_dbo' AS schema_name, 'Dealing_FailReasons_Top20_PIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_FailReasons_Top20_PIs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Fails_PI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Fails_PI] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_GS_Credit_Risk' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_GS_Credit_Risk] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_GSReconEODHolding' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_GSReconEODHolding] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_GSReconTrades' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_GSReconTrades]

