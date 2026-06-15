SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_CopierTable' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_CopierTable] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_DeviceID_AS_PI' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_DeviceID_AS_PI] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_DeviceID_Copiers' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_DeviceID_Copiers] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_DeviceID_Copy_Side' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_DeviceID_Copy_Side] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AML_PI_Abuse_DeviceID_PI_Side' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AML_PI_Abuse_DeviceID_PI_Side]

