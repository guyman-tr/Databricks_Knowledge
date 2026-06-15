SELECT
	c.*
   ,dc1.Name AS Country
FROM
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires  c
	JOIN DWH_dbo.Dim_Customer dc
		ON c.CID = dc.RealCID
	JOIN DWH_dbo.Dim_Country dc1
		ON dc.CountryID = dc1.CountryID
where FundingTypeID=2