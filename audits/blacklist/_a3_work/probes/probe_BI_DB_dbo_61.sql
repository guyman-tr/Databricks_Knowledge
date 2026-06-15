SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PositionPnL_UK_Instrument_Agg' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PositionPnL_UK_Instrument_Agg] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Positions_Closed_To_IBAN' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Positions_Closed_To_IBAN] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Positions_Opened_From_IBAN' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Positions_Opened_From_IBAN] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Post_Clsutering_Python' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Post_Clsutering_Python] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_PR_MonthlyData' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_PR_MonthlyData]

