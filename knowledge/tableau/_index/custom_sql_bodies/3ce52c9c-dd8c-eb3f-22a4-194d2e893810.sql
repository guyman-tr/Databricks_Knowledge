SELECT  * 
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User eboccsau
WHERE eboccsau.ToDate = '9999-12-31T00:00:00.000Z'
AND IsActive = 'true'