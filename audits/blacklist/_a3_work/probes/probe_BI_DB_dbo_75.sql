SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Rejected_Accounts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Rejected_Accounts] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Stocks_Activity_Apex' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Stocks_Activity_Apex] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Stocks_Activity_eToroDB' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Stocks_Activity_eToroDB] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Transactions_Trading_Activity' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Transactions_Trading_Activity] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Citizens_Under_Non_US_Regulation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Citizens_Under_Non_US_Regulation]

