SELECT bddcr.Date
	  ,bddcr.DateID
	  ,YEAR(Date)*100+dd.SSWeekNumberOfYear AS YearWeek
	  ,CONVERT(CHAR(8),YEAR(Date),112)*10000 +MONTH(Date)*100+SSWeekNumberOfMonth AS WeekofMonth
	  ,bddcr.ParentCID
	  ,dc.UserName
	  ,bddcr.AccountTypeID
	  ,bddcr.Revenue_Copy
FROM BI_DB_DailyCopyRevenue bddcr WITH (NOLOCK)
JOIN DWH..Dim_Customer dc WITH (NOLOCK)
ON dc.RealCID = bddcr.ParentCID
JOIN DWH..Dim_Date dd
ON dd.DateKey = bddcr.DateID
AND bddcr.AccountTypeID=9
WHERE bddcr.ParentCID IN (6215327,6421394,6656088,11682551,10155159,10787750,9662647,20871420,24001250,27259926)