SELECT cc.Date
	  ,cc.DateInt
	  ,cc.Club
	  ,cc.Amount
	  ,cc.CountryID
	  ,dd.CalendarYearQtr
	  ,CASE WHEN dc1.Name IN ('Denmark','Finland','Netherlands','Norway','Sweden')  THEN 'Nordic'
            WHEN dc1.Name IN ('Poland','Romania','Slovakia','Slovenia','Czech Republic') THEN 'EE'
            WHEN dc1.Region IN ('South & Central America','Spain') THEN 'Spanish'
            WHEN dc1.Region IN ('Other Asia','China') THEN 'SEA'
            WHEN dc1.Region IN ('Arabic Other','Arabic GCC') THEN 'Arabic'
            WHEN dc1.Region IN ('French','German','Italian','UK','USA','Australia','Canada') THEN dc1.Region
            ELSE 'ROW' END ClubRegion
	  ,DENSE_RANK() OVER (PARTITION BY dd.CalendarYearQtr ORDER BY cc.DateInt DESC) RowNumber
FROM BI_DEV.dbo.BI_DB_Daily_Club_From_fsc cc
 JOIN DWH.dbo.Dim_Date dd
 ON cc.DateInt = dd.DateKey
  JOIN DWH.dbo.Dim_Country dc1
 ON cc.CountryID = dc1.CountryID