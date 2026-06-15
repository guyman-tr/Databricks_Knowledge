SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ActiveAffActualMonthly_Region_GroupAffName' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ActiveAffActualMonthly_Region_GroupAffName] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_ActiveAffiliatesPlanned_Actual' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_ActiveAffiliatesPlanned_Actual] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Affiliate_Fraud_Loss' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Affiliate_Fraud_Loss] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_Affiliate_Guidlines_Report' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_Affiliate_Guidlines_Report] UNION ALL
SELECT 'BI_DB_dbo' AS schema_name, 'BI_DB_AffiliateCOAbuse' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [BI_DB_dbo].[BI_DB_AffiliateCOAbuse]

