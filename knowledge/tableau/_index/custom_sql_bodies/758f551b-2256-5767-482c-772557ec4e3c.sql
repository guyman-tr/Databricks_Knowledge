SELECT dc.RealCID,
        dc.CountryID,
		dc1.Name AS Country_Name,
		dr.Name AS Regulation
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Country dc1
	ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_Regulation dr
	ON dc.RegulationID = dr.ID