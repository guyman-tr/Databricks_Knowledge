SELECT
	   a.Metric
	 , a.IncomeCategory
	 , a.InstrumentTypeID
	 , a.IsSettled
	 , sum(a.Amount) AS Amount
	, di.InstrumentType
	, CASE WHEN a.IsSettled = 1 THEN 'Real' 
			WHEN a.IsSettled = 0 THEN 'CFD'
	  ELSE 'NA' 
	  END AS CFD_Real
  , YEAR(a.Date) AS [Year]
  , YEAR(a.Date) * 100 + DATEPART(qq, a.Date) AS YearQuarter
  , convert(varchar(6),a.Date,112) AS YearMonth
  , dd.ISOYearAndWeekNumber AS YearWeek
  , dd.DayNumberOfWeek_Sun_Start AS DayNumberOfWeek_Sun_Start
  , DATEDIFF (WEEK, a.Date, getdate()-1) AS WeekDiff
  , CASE WHEN DATEDIFF (WEEK, a.Date, getdate()-1) <= 7 THEN 1 ELSE 0 END AS IsLast8Weeks
  , CASE WHEN YEAR(a.Date) = year (getdate()-1) THEN 1 ELSE 0 END AS IsCurrentYear
  , CASE WHEN YEAR(a.Date) = year (getdate()-1) - 1 THEN 1 ELSE 0 END AS IsPreviousYear
  , CASE WHEN Month(a.Date) = Month (getdate()-1) THEN 1 ELSE 0 END AS IsCurrentMonth
  , CASE WHEN Month(a.Date) = Month (getdate()-1) - 1 THEN 1 ELSE 0 END AS IsPreviousMonth
  , CASE WHEN a.Date BETWEEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), CAST(getdate()-1 AS DATE)) AND getdate()-1 THEN 1 ELSE 0 END AS IsCurrentWeek
  , CASE WHEN a.Date BETWEEN DATEADD(WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AND DATEADD(DAY, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) THEN 1 ELSE 0 END AS IsPreviousWeek
  , CASE WHEN dd.DayNumberOfWeek_Sun_Start = (DATEPART(WEEKDAY,getdate()-1) + @@DATEFIRST - 1) % 7 + 1 THEN 1 ELSE 0 END AS IsSameWeekDayAsReference
FROM 
(
SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112) AS [Date]
	  , frfc.DateID
	  , 'FullCommission' AS Metric
	  , 'OpenClosePosition' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.FullCommissions) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'TicketFee' AS Metric
	  , 'OpenClosePosition' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.TicketFee) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112) 
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'TicketFeeByPercent' AS Metric
	  , 'OpenClosePosition' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.TicketFeeByPercent) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112) 
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'RollOverFee' AS Metric
	  , 'Overnight' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.RollOverFee) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'AdminFee' AS Metric
	  , 'Overnight' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.AdminFee) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112) 
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'SpotAdjustFee' AS Metric
	  , 'Overnight' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.SpotAdjustFee) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'Volume' AS Metric
	  , 'NA' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (ISNULL(frfc.VolumeOnOpen,0) + ISNULL(frfc.VolumeOnClose,0)) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]	  


UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'InvestedAmountOpen' AS Metric
	  , 'NA' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.InvestedAmountOpen) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

UNION ALL 

SELECT CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  AS [Date]
	  , frfc.DateID
	  , 'CountUU' AS Metric
	  , 'NA' AS IncomeCategory
	  , frfc.InstrumentTypeID
	  , ISNULL(frfc.IsSettled,0) AS IsSettled
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]
	  , SUM (frfc.CountUU) AS Amount
FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg frfc
WHERE DateID BETWEEN CAST (FORMAT (CAST (DATEFROMPARTS (YEAR (getdate()-1)-1, 1, 1) AS DATE), 'yyyyMMdd') AS INT) and CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
		frfc.DateID 
	  , frfc.DateID
	  , frfc.InstrumentTypeID
	  , frfc.IsSettled
	  , CONVERT(DATE, CONVERT(VARCHAR(8), frfc.DateID), 112)  
	  , frfc.Region
	  , frfc.Club
	  , frfc.[FTD Year]

) a
	JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType FROM DWH_dbo.Dim_Instrument) di
		ON a.InstrumentTypeID = di.InstrumentTypeID
	JOIN DWH_dbo.Dim_Date dd
		ON a.DateID = dd.DateKey
GROUP BY 
	a.Metric
  , a.IncomeCategory
  , a.InstrumentTypeID
  , a.IsSettled
  , di.InstrumentType
  , CASE WHEN a.IsSettled = 1 THEN 'Real' WHEN a.IsSettled = 0 THEN 'CFD' ELSE 'NA'  END 
  ,	YEAR(a.Date) 
  , YEAR(a.Date) * 100 + DATEPART(qq, a.Date) 
  , convert(varchar(6),a.Date,112) 
  , dd.ISOYearAndWeekNumber 
  , dd.DayNumberOfWeek_Sun_Start 
  , DATEDIFF (WEEK, a.Date, getdate()-1)
  , CASE WHEN DATEDIFF (WEEK, a.Date, getdate()-1) <= 7 THEN 1 ELSE 0 END 
  , CASE WHEN YEAR(a.Date) = year (getdate()-1) THEN 1 ELSE 0 END
  , CASE WHEN YEAR(a.Date) = year (getdate()-1) - 1 THEN 1 ELSE 0 END 
  , CASE WHEN Month(a.Date) = Month (getdate()-1) THEN 1 ELSE 0 END 
  , CASE WHEN Month(a.Date) = Month (getdate()-1) - 1 THEN 1 ELSE 0 END 
  , CASE WHEN a.Date BETWEEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), CAST(getdate()-1 AS DATE)) AND getdate()-1 THEN 1 ELSE 0 END 
  , CASE WHEN a.Date BETWEEN DATEADD(WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AND DATEADD(DAY, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) THEN 1 ELSE 0 END 
  , CASE WHEN dd.DayNumberOfWeek_Sun_Start = (DATEPART(WEEKDAY,getdate()-1) + @@DATEFIRST - 1) % 7 + 1 THEN 1 ELSE 0 END