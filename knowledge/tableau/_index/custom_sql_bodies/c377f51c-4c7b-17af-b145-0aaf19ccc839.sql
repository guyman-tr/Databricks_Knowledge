SELECT 
a.CID
,a.DividendYearMonth
,a.IsSettled
,dc1.Name AS 'DimCustomer_Country'
,b1.TIN_CountryName AS 'TIN_Country'
,CASE WHEN b1.CID IS NULL THEN 'No' WHEN b1.CID IS NOT NULL THEN 'Yes' END AS 'Has_TIN_Data'
,dr.Name AS 'Regulation_Name'
,b.W8SignDate
,CASE WHEN b.W8SignDate IS NULL THEN 'No' WHEN b.W8SignDate IS NOT NULL THEN 'Yes' ELSE 'N/A' END AS 'Is_W8_Signed'
,CASE WHEN b.W8SignDate < '20200220' THEN 'Old' WHEN b.W8SignDate >= '20200220' THEN 'New' ELSE 'N/A' END AS 'W8_Version'

FROM 
(SELECT 
a.PaymentDate AS 'DividendDate'
,a.RealCID AS 'CID'
,EOMONTH(a.PaymentDate) AS 'DividendYearMonth'
,a.IsSettled
,ROW_NUMBER() OVER(PARTITION BY a.RealCID, EOMONTH(a.PaymentDate), a.IsSettled ORDER BY a.PaymentDate) AS 'RNLine'
FROM BI_DB.dbo.BI_DB_Daily_CID_Dividend_TaxReport a
WHERE a.TaxCode IN ('6', '27', '40')
)a

LEFT JOIN DWH.dbo.Dim_Customer dc ON a.CID = dc.RealCID

INNER JOIN DWH.dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
INNER JOIN DWH.dbo.Dim_Regulation dr ON dc.RegulationID = dr.DWHRegulationID

LEFT JOIN BI_DB.dbo.BI_DB_Tax_Compliance_W8 b ON a.CID = b.CID 
LEFT JOIN BI_DB.dbo.BI_DB_Tax_Compliance_TIN b1 ON a.CID = b1.CID

WHERE a.RNLine = 1