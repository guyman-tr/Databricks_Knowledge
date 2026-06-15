select r.*,
country.Name AS Country
FROM BI_DB.dbo.BI_DB_STP_Redeems r
LEFT JOIN DWH.dbo.Dim_Customer c ON c.RealCID=r.CID
LEFT JOIN DWH.dbo.Dim_Country country ON country.CountryID=c.CountryID