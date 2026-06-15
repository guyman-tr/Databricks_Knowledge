SELECT dd.FullDate
      ,dd.CalendarYearMonth
      ,dd.MonthName+' '+ CAST(dd.CalendarYear AS VARCHAR(30)) AS YearMonth
FROM [DWH_dbo].[Dim_Date] dd WITH (NOLOCK)