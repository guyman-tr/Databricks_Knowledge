SELECT a.*, b.CountryID, c.RiskGroupID
FROM BI_DB.dbo.BI_DB_RiskClassification_Scores a
LEFT JOIN DWH.dbo.Dim_Customer b ON a.CID = b.RealCID
JOIN DWH.dbo.Dim_Country c ON b.CountryID = c.CountryID
WHERE a.CID IN (<[Parameters].[Parameter 1]>)