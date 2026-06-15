SELECT 'BI_DB_dbo' AS schema_name, 'AML_German_Video_Ident' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[AML_German_Video_Ident] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'AML_InstrumentMetaData_Daily_Email' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'AML_InstrumentMetaData_Daily_Email_DayToDay_Changes' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email_DayToDay_Changes] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AccountClosure' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AccountClosure] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AcquisitionFunnel_AGG' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AcquisitionFunnel_AGG]

