SELECT dd.DateKey
      ,dd.FullDate 
      ,dd.ISOYearAndWeekNumber
	  ,dd.DayNumberOfYear
	  ,dd.DaysSince1900
	  ,dd.CalendarYearMonth
	  ,dd.CalendarYearQtr
	  ,dd.CalendarSemester
	  ,dd.CalendarQuarter
	  ,dd.IsLastDayOfMonth
	  ,dd.IsWeekday
	  ,dd.IsWeekend
	  ,dd.IsFirstDayOfMonth
FROM [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)