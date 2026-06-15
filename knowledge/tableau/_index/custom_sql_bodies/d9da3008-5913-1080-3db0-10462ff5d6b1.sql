SELECT 
a.CID
,CAST(a.UpdateDate AS DATE) AS 'US Trades Test Date'
,b.W8SignDate AS 'W8 Sign Date'
,CASE WHEN b.W8SignDate IS NULL THEN 'No' WHEN b.W8SignDate IS NOT NULL THEN 'Yes' ELSE 'N/A' END AS 'Is W8 Signed'
,CASE WHEN b.W8SignDate < '20200220' THEN 'Old' WHEN b.W8SignDate >= '20200220' THEN 'New' ELSE 'N/A' END AS 'W8_Version'
FROM BI_DB.dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks a
LEFT JOIN BI_DB.dbo.BI_DB_Tax_Compliance_W8 b ON a.CID = b.CID