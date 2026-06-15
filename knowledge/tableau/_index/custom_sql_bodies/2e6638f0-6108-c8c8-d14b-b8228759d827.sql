SELECT c.*, dc1.Name as Country, ft.Name as FundingType,
CASE WHEN c.HoursBetween<=2 THEN 'A: <=2 hrs'
WHEN c.HoursBetween<=4 THEN 'B: <=4 hrs'
WHEN c.HoursBetween<=6 THEN 'C: <=6 hrs'
WHEN c.HoursBetween<=8 THEN 'D: <=8 hrs'
WHEN c.HoursBetween<=10 THEN 'E: <=10 hrs'
WHEN c.HoursBetween<=12 THEN 'F: <=12 hrs'
WHEN c.HoursBetween<=16 THEN 'G: <=16 hrs'
WHEN c.HoursBetween<=18 THEN 'H: <=18 hrs'
WHEN c.HoursBetween<=20 THEN 'I: <=20 hrs'
WHEN c.HoursBetween<=22 THEN 'J: <=22 hrs'
WHEN c.HoursBetween<=24 THEN 'K: <=24 hrs'
ELSE 'L: >24 Hrs' END AS HoursDistribution
FROM BI_DB_Operations_Monthly_KPIs_Cashouts c
join DWH..Dim_Customer dc on c.CID = dc.RealCID
join DWH..Dim_Country dc1 on dc.CountryID = dc1.CountryID
join DWH..Dim_FundingType ft on ft.FundingTypeID=c.FundingTypeID