SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Extented_Hours_NewCID' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Extented_Hours_NewCID] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_Extented_Hours_Volume' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_Extented_Hours_Volume] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_FailReasons' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_FailReasons] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_FailReasons_PIs' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_FailReasons_PIs] UNION ALL
SELECT 'Dealing_dbo' AS schema_name, 'Dealing_FailReasons_Top20' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [Dealing_dbo].[Dealing_FailReasons_Top20]

