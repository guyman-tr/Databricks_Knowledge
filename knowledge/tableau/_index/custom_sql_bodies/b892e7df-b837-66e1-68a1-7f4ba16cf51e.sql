SELECT tt.ActiveDate
	  ,tt.NewMarketingRegion
	  ,tt.CalendarYearQtr
	  ,tt.MonthNumberOfQuarter
	  ,tt.NetDeposits
	  ,tt.Revenue_Total
	  ,tt.Cashouts_Total
	  ,tt.ClubMember
		,LAG(tt.ClubMemberLastQ) OVER (PARTITION BY tt.NewMarketingRegion ORDER BY tt.MonthNumberOfQuarter) ClubMemberLastQ
FROM 
(SELECT mp.ActiveDate
		,CASE WHEN mp.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE mp.NewMarketingRegion END NewMarketingRegion
		,dd.CalendarYearQtr
		,dd.MonthNumberOfQuarter
		,SUM( mp.TotalDeposits-mp.CashoutsAdjusted) NetDeposits
		,SUM(CASE WHEN mp.EOM_Club NOT LIKE ('%Bronze%') THEN mp.Revenue_Total ELSE mp.Revenue_Total END ) Revenue_Total
         ,SUM(CASE WHEN mp.EOM_Club NOT LIKE ('%Bronze%') AND mp.IsEOM_Funded_NEW = 1  THEN 1 ELSE 0 END ) ClubMember
		,SUM(CASE WHEN mp.EOM_Club NOT LIKE ('%Bronze%')   THEN mp.TotalCashouts END ) Cashouts_Total
		,MAX(cc.ClubMember) ClubMemberLastQ
		 ,SUM(CASE WHEN mp.EOM_Club NOT LIKE ('%Bronze%') AND dd.MonthNumberOfYear IN (3,6,9,12)
		  AND mp.IsEOM_Funded_NEW = 1  THEN 1 ELSE 0 END ) ClubMembers
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN DWH_dbo.Dim_Date dd
ON dd.FullDate = mp.ActiveDate
 JOIN (SELECT mp.ActiveDate
		,dd.CalendarYearQtr
		,CASE WHEN mp.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE mp.NewMarketingRegion END NewMarketingRegion
		,SUM(CASE WHEN mp.EOM_Club NOT LIKE ('%Bronze%') AND mp.IsEOM_Funded_NEW = 1  THEN 1 ELSE 0 END ) ClubMember
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN DWH_dbo.Dim_Date dd
ON dd.FullDate = mp.ActiveDate
WHERE mp.ActiveDate>='2024-01-01'
AND dd.MonthNumberOfYear IN (3,6,9,12)
GROUP BY mp.ActiveDate
,CASE WHEN mp.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE mp.NewMarketingRegion END 
,dd.CalendarYearQtr) cc
ON cc.CalendarYearQtr = dd.CalendarYearQtr
AND cc.NewMarketingRegion = CASE WHEN mp.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE mp.NewMarketingRegion END 
WHERE mp.ActiveDate>='2025-02-01'
GROUP BY mp.ActiveDate
		,CASE WHEN mp.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE mp.NewMarketingRegion END
		,dd.CalendarYearQtr
		,dd.MonthNumberOfQuarter) tt