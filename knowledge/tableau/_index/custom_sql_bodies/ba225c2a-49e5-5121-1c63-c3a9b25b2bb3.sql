SELECT bdcdd.* 
       ,bb.AvailableCash
	   ,bb.InProcessCashouts
FROM (
SELECT * 
    ,CASE WHEN aa.LastMonthOfQuarter = aa.MonthOfDate THEN aa.QuarterOfDate_tmp ELSE 0 END AS QuarterOfDate
FROM  (
SELECT *
      ,CASE WHEN MONTH(bdcdd.ActiveDate) IN (1,2,3) THEN 3
		      WHEN MONTH(bdcdd.ActiveDate) IN (4,5,6) THEN 6
				WHEN MONTH(bdcdd.ActiveDate) IN (7,8,9) THEN 9
				WHEN MONTH(bdcdd.ActiveDate) IN (10,11,12) THEN 12
				END AS LastMonthOfQuarter
      ,DATEPART(Quarter,bdcdd.ActiveDate) QuarterOfDate_tmp
		,DATEPART(MONTH,bdcdd.ActiveDate) MonthOfDate
	
FROM  dbo.BI_DB_CorpDevDashboard bdcdd


) aa
) bdcdd 
LEFT JOIN 
(
SELECT dd.FullDate
  ,CASE WHEN  bdcd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
             WHEN bdcd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
				 WHEN bdcd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
				 ELSE 'Europe' END AS Region
    
      ,SUM(vl.TotalCash) AvailableCash
	  ,SUM(vl.InProcessCashouts) InProcessCashouts
FROM DWH..V_Liabilities vl WITH(NOLOCK)
JOIN BI_DB..BI_DB_CIDFirstDates bdcd WITH(NOLOCK)
ON vl.CID = bdcd.CID
JOIN DWH..Dim_Date dd
ON dd.DateKey = vl.DateID
WHERE dd.IsLastDayOfMonth = 'Y'
AND dd.DateKey >= 20150101
GROUP BY dd.FullDate
  ,CASE WHEN  bdcd.Region IN( 'South & Central America','USA','Canada') THEN 'Americas'
             WHEN bdcd.Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
				 WHEN bdcd.Region IN('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
				 ELSE 'Europe' END 
    
) bb
ON EOMONTH(bdcdd.ActiveDate) = bb.FullDate
AND bdcdd.Indicator = 'AUA'
AND bb.Region = bdcdd.Region