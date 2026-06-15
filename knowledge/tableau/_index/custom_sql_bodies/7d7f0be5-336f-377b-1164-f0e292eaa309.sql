select 
a.* ,
dc.Name as Country,
ft.Name as FundingType,
CASE WHEN a.HoursBetween<=2 THEN 'A: <=2 hrs'
WHEN a.HoursBetween<=4 THEN 'B: <=4 hrs'
WHEN a.HoursBetween<=6 THEN 'C: <=6 hrs'
WHEN a.HoursBetween<=8 THEN 'D: <=8 hrs'
WHEN a.HoursBetween<=10 THEN 'E: <=10 hrs'
WHEN a.HoursBetween<=12 THEN 'F: <=12 hrs'
WHEN a.HoursBetween<=16 THEN 'G: <=16 hrs'
WHEN a.HoursBetween<=18 THEN 'H: <=18 hrs'
WHEN a.HoursBetween<=20 THEN 'I: <=20 hrs'
WHEN a.HoursBetween<=22 THEN 'J: <=22 hrs'
WHEN a.HoursBetween<=24 THEN 'K: <=24 hrs'
ELSE 'L: >24 Hrs' END AS HoursDistribution
from BI_DB.[dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates] a
join DWH.dbo.Dim_Customer c on c.RealCID=a.CID
LEFT JOIN DWH.dbo.Dim_Country dc on dc.CountryID=c.CountryID
left join DWH.dbo.Dim_FundingType ft on ft.FundingTypeID=a.FundingTypeID