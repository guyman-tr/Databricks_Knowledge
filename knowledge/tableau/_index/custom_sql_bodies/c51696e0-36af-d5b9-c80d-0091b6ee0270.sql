SELECT 
dc.Name AS 'Country'
,dc.CountryID
,dc.RiskGroupID
,dc.IsHighRiskCountry
,dc.RegulationID
,dr.Name AS 'Regulation'
,dc.UpdateDate
FROM DWH.dbo.Dim_Country dc WITH(NOLOCK)
INNER JOIN DWH.dbo.Dim_Regulation dr WITH(NOLOCK) ON dc.RegulationID = dr.DWHRegulationID