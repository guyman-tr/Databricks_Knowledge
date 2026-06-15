SELECT dd.CalendarYearMonth
        ,MAX(dd.FullDate) FullDate
        ,COUNT(DISTINCT dd.DateKey) DaysMTD
        ,COUNT(DISTINCT dd1.DateKey) DaysInMonth
FROM [DWH_dbo].[Dim_Date] dd WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Date] dd1 WITH (NOLOCK)
ON dd.CalendarYearMonth = dd1.CalendarYearMonth
AND dd1.IsWeekday = 'Y'
WHERE dd.IsWeekday = 'Y'
AND dd.DateKey <=CONVERT(CHAR(8),GETDATE()-1,112)
AND dd.DateKey >=CONVERT(CHAR(8),GETDATE()-130,112)
GROUP BY dd.CalendarYearMonth