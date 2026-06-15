SELECT 
bdcbcln.Country, sum( bdcbcln.NOPCryptoCFD) NOPCryptoCFD
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbcln
WHERE bdcbcln.DateID = <[Parameters].[Parameter 2]>
AND bdcbcln.IsValidCustomer=1 
AND bdcbcln.IsCreditReportValidCB=1
GROUP BY bdcbcln.Country