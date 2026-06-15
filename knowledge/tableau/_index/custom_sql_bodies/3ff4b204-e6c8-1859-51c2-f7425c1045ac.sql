select 	
	red.CID, 
	red.RedeemID,
        red.AmountOnClose,
	dr.Name as Regulation,
	DATEDIFF(YEAR,dc.BirthDate, GETDATE()) AS Age,
	dr1.Name AS DesignatedRegulation,
	country.Name AS Country,
	CAST(red.RequestDate AS DATEtime) AS RequestDate,
	CAST([LastModificationDate] AS DATEtime) AS ModificationDate,
	DATEDIFF(HOUR,red.RequestDate,LastModificationDate) AS DiffHours,
	DATENAME(WEEKDAY,red.RequestDate) AS RequestNameDay,
	DATENAME(WEEKDAY,red.LastModificationDate) AS ModificattonNameDay,
	DATEDIFF(DAY,red.RequestDate,LastModificationDate) AS DayDiff,
	DATEDIFF(hour,red.RequestDate,LastModificationDate) AS HOurDiff,
	CASE WHEN DATEDIFF(day,red.RequestDate,LastModificationDate)<=1 THEN '1'
	WHEN DATENAME(WEEKDAY,red.RequestDate) IN ('Friday') AND DATEDIFF(day,red.RequestDate,LastModificationDate)<=3 THEN '1'
	WHEN DATENAME(WEEKDAY,red.RequestDate) IN ('Saturday') AND DATEDIFF(day,red.RequestDate,LastModificationDate)<=2 THEN '1'ELSE '0' END AS "SLA",
		CASE WHEN DATEDIFF(hour,red.RequestDate,LastModificationDate)<=24 THEN '1'
	WHEN DATENAME(hour,red.RequestDate) IN ('Friday') AND DATEDIFF(hour,red.RequestDate,LastModificationDate)<=96 THEN '1'
	WHEN DATENAME(WEEKDAY,red.RequestDate) IN ('Saturday') AND DATEDIFF(day,red.RequestDate,LastModificationDate)<=72 THEN '1'ELSE '0' END AS "SLAhrs"
	,	EOMONTH(red.LastModificationDate) as LastModificationDateEOMonth
from  [DWH_dbo].[Fact_BillingRedeem] red
join DWH_dbo.Dim_Customer dc on dc.RealCID=red.CID
JOIN DWH_dbo.Dim_Country country ON country.CountryID=dc.CountryID
JOin DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
JOin DWH_dbo.Dim_Regulation dr1 on dr1.ID=dc.DesignatedRegulationID
where red.RedeemStatusID =8 --TransactionDone
and red.RequestDate>=DATEADD(year,DATEDIFF(year,0,getdate())-2,0)