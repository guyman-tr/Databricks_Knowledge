SELECT 'Dealing_dbo' AS schema_name, 'Dealing_NOP_LPandClients' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_NOP_LPandClients] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_NOP_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_NOP_Report] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_NOPDistribution' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_NOPDistribution] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_NumberofPositionsOpened_Agg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_NumberofPositionsOpened_Agg] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_OfferedInstruments' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_OfferedInstruments]

