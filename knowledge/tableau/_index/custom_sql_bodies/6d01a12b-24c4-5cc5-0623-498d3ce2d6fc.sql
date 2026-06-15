Select 
 count(dc.GCID) as 'Number of Users'
  
 , dr.Name as Regulation
 , c.Name as Country
 , dc.IsValidCustomer
  from DWH.dbo.Dim_Customer dc
 JOIN DWH.dbo.Dim_Country c on dc.CountryID = c.CountryID
 JOIN DWH.dbo.Dim_Regulation dr on dr.DWHRegulationID = dc.RegulationID 
 
 WHERE dc.VerificationLevelID =3
 GROUP BY c.Name,dr.Name,dc.IsValidCustomer