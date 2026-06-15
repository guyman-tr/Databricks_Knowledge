SELECT CONVERT(date, convert(varchar(10), bddda.DateID)) [Date],
bddda.Country,
bddda.Region,
SUM(bddda.FirstDepositors) FTDs,
SUM(bddda.Registrations) Registerations,
SUM(Revenue) 'Revenue'
FROM BI_DB..BI_DB_DDR_Daily_Aggregated bddda
WHERE DateID>=20220101
GROUP BY bddda.DateID,
bddda.Country,
bddda.Region