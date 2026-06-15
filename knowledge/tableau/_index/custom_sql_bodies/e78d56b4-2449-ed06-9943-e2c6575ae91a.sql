SELECT dd.DateKey
      ,dd.FullDate
      ,dd.DayNumberOfYear
      ,dd.DayNumberOfQuarter
      ,dd.DayNumberOfMonth
      ,dd.DayNumberOfWeek_Sun_Start
      ,dd.MonthNumberOfYear
      ,dd.MonthNumberOfQuarter
      ,dd.CalendarYearMonth
      ,dd.CalendarYearQtr
      ,dd.MonthNameAbbreviation
      ,dd.DayName
      ,dd.IsLastDayOfMonth
      ,dd.ISOYearAndWeekNumber
FROM DWH.dbo.Dim_Date dd WITH (NOLOCK)