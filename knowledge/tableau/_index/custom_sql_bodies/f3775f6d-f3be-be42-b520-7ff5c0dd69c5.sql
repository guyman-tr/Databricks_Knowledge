SELECT
	c.*
   ,dc1.Name AS Country
   ,r.Name as DesignatedRegulation
   ,EOMONTH(c.ModificationDate) AS ModificationDateEOMonth
FROM
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires  c
	JOIN DWH_dbo.Dim_Customer dc
		ON c.CID = dc.RealCID
	JOIN DWH_dbo.Dim_Country dc1
		ON dc.CountryID = dc1.CountryID
		JOIN DWH_dbo.Dim_Regulation r on r.ID = dc.DesignatedRegulationID
where FundingTypeID=2 and c.ModificationDate >= '2025-01-01'