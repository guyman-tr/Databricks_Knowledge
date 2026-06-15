SELECT b.CID,
       CAST(b.FirstDepositDate AS DATE) Date,
	   DATENAME(WEEKDAY, CAST(b.FirstDepositDate AS DATE)) WeekDay,
	   YEAR(b.FirstDepositDate) YearFTD,
	   weekID.FirstDateWeekID,
	   weekID.FirstDateWeekDate,
	   CASE WHEN b.FirstAction IN ('Copy','Copy Fund') THEN 'Copy' ELSE b.FirstAction END FirstAction,
	   b.NewMarketingRegion Region
FROM BI_DB_dbo.BI_DB_First5Actions b
JOIN (SELECT dd.SSWeekNumberOfYear, dd.CalendarYear, MIN(dd.DateKey) FirstDateWeekID, MIN(dd.FullDate)FirstDateWeekDate
      FROM DWH_dbo.Dim_Date dd
	  WHERE YEAR(dd.FullDate)>=2023
      GROUP BY dd.SSWeekNumberOfYear, dd.CalendarYear) weekID ON  weekID.SSWeekNumberOfYear=DATEPART(WEEK,b.FirstDepositDate) AND weekID.CalendarYear=YEAR(b.FirstDepositDate)
WHERE CAST(b.FirstDepositDate AS DATE)>=DATEADD(MONTH,-3,GETDATE())