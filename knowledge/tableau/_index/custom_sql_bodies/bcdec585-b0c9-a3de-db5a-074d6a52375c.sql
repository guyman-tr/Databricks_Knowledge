SELECT o.*,
r.Name AS Regulation,
country.Name AS Country
FROM BI_DB.dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard o
LEFT JOIN DWH.dbo.Dim_Customer c ON c.RealCID=o.CID
LEFT JOIN DWH.dbo.Dim_Regulation r ON r.ID=c.RegulationID
LEFT JOIN DWH.dbo.Dim_Country country ON country.CountryID=c.CountryID