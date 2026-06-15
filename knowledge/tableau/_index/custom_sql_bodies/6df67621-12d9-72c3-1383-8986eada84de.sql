SELECT fca.DateID,
       DATENAME(WEEKDAY, CAST(fca.Occurred AS DATE)) WeekDay,
	   YEAR(fca.Occurred) OccurredYear,
	   DATEPART(WEEK,fca.Occurred) WeekNum,
	   weekID.FirstDateWeekID,
	   weekID.FirstDateWeekDate,
	   dpl.Name Club,
	   b.ClusterSF,
       SUM(CASE WHEN fca.ActionTypeID=7 THEN fca.Amount END) Deposits,
	   SUM(CASE WHEN fca.ActionTypeID=8 THEN fca.Amount END) Cashout
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Customer dc ON fca.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Date dd ON dd.DateKey=fca.DateID
JOIN (SELECT dd.SSWeekNumberOfYear, dd.CalendarYear, MIN(dd.DateKey) FirstDateWeekID, MIN(dd.FullDate)FirstDateWeekDate
      FROM DWH_dbo.Dim_Date dd
	  WHERE YEAR(dd.FullDate)>=2022
      GROUP BY dd.SSWeekNumberOfYear, dd.CalendarYear) weekID ON  weekID.SSWeekNumberOfYear=DATEPART(WEEK,fca.Occurred) AND weekID.CalendarYear=YEAR(fca.Occurred)
LEFT JOIN BI_DB_dbo.BI_DB_CID_DailyCluster b ON b.CID=fca.RealCID AND b.IsLastCluster=1
WHERE fca.ActionTypeID IN (7,8)
AND YEAR(fca.Occurred)>=2022 
GROUP BY fca.DateID, DATENAME(WEEKDAY, CAST(fca.Occurred AS DATE)), YEAR(fca.Occurred), DATEPART(WEEK,fca.Occurred), dpl.Name, b.ClusterSF,weekID.FirstDateWeekID,weekID.FirstDateWeekDate