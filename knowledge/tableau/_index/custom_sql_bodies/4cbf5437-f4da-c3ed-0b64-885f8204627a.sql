SELECT  dd.FullDate
	         ,dd.CalendarYear
			 ,dd.CalendarYearMonth
	         ,REPLACE(dd.CalendarYearQtr,'-','Q') CalendarYearQtr
      FROM DWH_dbo.Dim_Date dd WITH (NOLOCK)
	  WHERE dd.CalendarYear >=2023
	  AND dd.FullDate <=GETDATE()