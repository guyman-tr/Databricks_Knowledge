SELECT
	dc.RealCID
	,dc.ReferralID
	,dc.RegisteredReal
,dc1.Name as KYCCountry
FROM
	DWH_dbo.Dim_Customer dc	
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
WHERE 
	dc.ReferralID <> 0