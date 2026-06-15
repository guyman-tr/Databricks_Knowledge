SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Corporate_CA_Apex' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_Apex] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Corporate_CA_etoro' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_etoro] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Fees_Charge' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Fees_Charge] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Instrument_Holders' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Instrument_Holders] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts]

