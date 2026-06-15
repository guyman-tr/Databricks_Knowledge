SELECT EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID))) AS OccurredMonth
, 'Not FCA, UK Region' AS ClientCategory
, SUM(ISNULL(ddr.TotalCommission, 0)) AS TotalCommission
, SUM(ISNULL(ddr.FullTotalCommission, 0)) AS FullTotalCommission
, SUM(ISNULL(ddr.ActiveOpen, 0)) AS ActiveOpen
FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr
WHERE (ddr.Regulation <> 'FCA' AND ddr.Region = 'UK') 
AND ddr.DateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and ddr.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND ddr.TimeRange = 'Yesterday' 
AND ddr.IsValidCustomer = 1 
AND ddr.IsCreditReportValidCB = 1
GROUP BY EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID)))

UNION ALL

SELECT EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID))) AS OccurredMonth
, 'FCA, Not UK Region' AS ClientCategory
, SUM(ISNULL(ddr.TotalCommission, 0)) AS TotalCommission
, SUM(ISNULL(ddr.FullTotalCommission, 0)) AS FullTotalCommission
, SUM(ISNULL(ddr.ActiveOpen, 0)) AS ActiveOpen
FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr
WHERE (ddr.Regulation = 'FCA' AND ddr.Region <> 'UK') 
AND ddr.DateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and ddr.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND ddr.TimeRange = 'Yesterday' 
AND ddr.IsValidCustomer = 1 
AND ddr.IsCreditReportValidCB = 1
GROUP BY EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID)))

UNION ALL

SELECT EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID))) AS OccurredMonth
, ddr.Regulation AS ClientCategory
, SUM(ISNULL(ddr.TotalCommission, 0)) AS TotalCommission
, SUM(ISNULL(ddr.FullTotalCommission, 0)) AS FullTotalCommission
, SUM(ISNULL(ddr.ActiveOpen, 0)) AS ActiveOpen
FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr
WHERE ddr.Regulation = 'FCA' 
AND  ddr.DateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and ddr.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND ddr.TimeRange = 'Yesterday' 
AND ddr.IsValidCustomer = 1 
AND ddr.IsCreditReportValidCB = 1
GROUP BY EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID)))
, ddr.Regulation

UNION ALL

SELECT EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID))) AS OccurredMonth
, ddr.Region AS ClientCategory
, SUM(ISNULL(ddr.TotalCommission, 0)) AS TotalCommission
, SUM(ISNULL(ddr.FullTotalCommission, 0)) AS FullTotalCommission
, SUM(ISNULL(ddr.ActiveOpen, 0)) AS ActiveOpen
FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr
WHERE ddr.Region = 'UK' 
AND ddr.DateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and ddr.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND ddr.TimeRange = 'Yesterday' 
AND ddr.IsValidCustomer = 1 
AND ddr.IsCreditReportValidCB = 1
GROUP BY EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID)))
, ddr.Region