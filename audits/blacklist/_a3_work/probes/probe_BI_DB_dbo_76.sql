SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Compliance_Apex_Clients' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Customer_Acount_Reconcilation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Customer_Acount_Reconcilation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Mailing_Address_Non_US_Regulation' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Mailing_Address_Non_US_Regulation] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_US_Mailing_Address_Non_US_Regulation_Email' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_US_Mailing_Address_Non_US_Regulation_Email]

