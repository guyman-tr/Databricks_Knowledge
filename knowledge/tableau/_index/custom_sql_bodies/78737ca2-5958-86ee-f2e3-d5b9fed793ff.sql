Select f.*, dc.CountryID from #final f
join DWH_dbo.Dim_Country dc on dc.Name=f.Country