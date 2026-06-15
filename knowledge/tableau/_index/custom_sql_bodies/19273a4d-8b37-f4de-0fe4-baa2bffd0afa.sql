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
      ,dd.PartitionID
FROM DWH.dbo.Dim_Date dd WITH (NOLOCK)
WHERE dd.PartitionID >= convert(CHAR(6),DATEADD(MONTH,<[Parameters].[Parameter 3]>,getdate()),112)