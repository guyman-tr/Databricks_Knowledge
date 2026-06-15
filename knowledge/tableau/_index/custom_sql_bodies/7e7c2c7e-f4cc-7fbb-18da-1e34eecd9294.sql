SELECT c.*, dc1.Name as Country, ft.Name AS FundingType
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts c
join DWH_dbo.Dim_Customer dc on c.CID = dc.RealCID
JOIN DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=c.FundingTypeID
join DWH_dbo.Dim_Country dc1 on dc.CountryID = dc1.CountryID