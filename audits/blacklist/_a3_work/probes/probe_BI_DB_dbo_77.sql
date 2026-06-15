SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Popular_Investor' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Popular_Investor] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Stocks_Apex_PFOF' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Stocks_Apex_PFOF] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Stocks_MAU_DAU_KPI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Stocks_MAU_DAU_KPI] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Stocks_Transactions_Per_Time_Unit' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Stocks_Transactions_Per_Time_Unit] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_USA_Equity_Deposits' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_USA_Equity_Deposits]

