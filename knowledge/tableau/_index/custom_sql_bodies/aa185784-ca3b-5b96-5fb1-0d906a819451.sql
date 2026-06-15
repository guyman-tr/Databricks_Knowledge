select 
A.AffiliateID, 
A.TradingAccount_RealCID, 
A.RegistrationFirstDate, 
A.AffiliatesGroupsName, 
dc1.FirstName +  ' ' + dc1.LastName as FullName,
A.EntityName,
dc.Name as Country,
A.ContactPersonFullName,
r.Name as Regulation

from DWH_dbo.Dim_Affiliate A
LEFT JOIN DWH_dbo.Dim_Country dc on dc.CountryID=A.CountryID
JOIN DWH_dbo.Dim_Customer dc1 ON dc1.RealCID=A.TradingAccount_RealCID
join DWH_dbo.Dim_Regulation r on r.ID=dc1.RegulationID
WHERE RegistrationFirstDate IS NOT NULL AND RegistrationFirstDate>='20240401'
AND Channel IN ('Affiliate') and AccountActivated=1