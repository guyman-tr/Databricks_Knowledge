select f.*,
datediff(year,dc.BirthDate,getdate()) as ClientAge,
dc1.Name as Citizenship,
dc2.Name as PlaceOfBirth,
ds.Name as ScreeningStatus
from #final f
join DWH_dbo.Dim_Customer dc on dc.RealCID=f.CID
left join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CitizenshipCountryID
left join DWH_dbo.Dim_Country dc2 on dc2.CountryID=dc.POBCountryID
left join DWH_dbo.Dim_ScreeningStatus ds on ds.ScreeningStatusID=dc.ScreeningStatusID