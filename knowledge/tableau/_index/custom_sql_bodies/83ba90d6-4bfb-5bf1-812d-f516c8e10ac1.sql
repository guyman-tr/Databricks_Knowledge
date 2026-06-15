SELECT *
FROM [BI_DB_dbo].[BI_DB_DCM_Dashboard] [BI_DB_DCM_Dashboard]
WHERE Date >='2021-12-01' 
AND BI_DB_DCM_Dashboard.Channel  IN ('Content Partnerships','Media Performance')
AND Date < CAST (GETDATE() AS DATE)