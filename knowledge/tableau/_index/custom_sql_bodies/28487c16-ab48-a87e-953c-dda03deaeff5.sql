SELECT tt.ActiveDate
	  ,tt.NewMarketingRegion
	  ,tt.CalendarYearQtr
	  ,tt.MonthNumberOfQuarter
	  ,tt.NetDeposits
	  ,tt.Revenue_Total
	  ,tt.Cashouts_Total
	  ,tt.ClubMember
		,LAG(tt.ClubMemberLastQ) OVER (PARTITION BY tt.NewMarketingRegion ORDER BY tt.MonthNumberOfQuarter) ClubMemberLastQ
FROM (
		SELECT DATEFROMPARTS(YEAR(bdcdpfd.ActiveDate), MONTH(bdcdpfd.ActiveDate), 1) AS ActiveDate
				,CASE WHEN bdcdpfd.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE bdcdpfd.NewMarketingRegion END AS NewMarketingRegion
				,dd.CalendarYearQtr
				,dd.MonthNumberOfQuarter
				,SUM(bdcdpfd.TotalDeposits-bdcdpfd.CashoutsAdjusted) NetDeposits
				,SUM(CASE WHEN bdcdpfd.EOD_Club NOT LIKE ('%Bronze%') THEN bdcdpfd.Revenue_Total ELSE bdcdpfd.Revenue_Total END) Revenue_Total
				,COUNT(DISTINCT CASE WHEN bdcdpfd.EOD_Club NOT LIKE ('%Bronze%') AND bdcdpfd.IsFunded_New=1 THEN bdcdpfd.CID END ) ClubMember
				,SUM(CASE WHEN bdcdpfd.EOD_Club NOT LIKE ('%Bronze%') THEN bdcdpfd.TotalCashouts END) Cashouts_Total
				,MAX(cc.ClubMember) ClubMemberLastQ
				 ,COUNT(DISTINCT CASE WHEN bdcdpfd.EOD_Club NOT LIKE ('%Bronze%')  AND dd.MonthNumberOfYear IN (3,6,9,12)
				  AND bdcdpfd.IsFunded_New=1  THEN bdcdpfd.CID END ) ClubMembers
		FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpfd
		JOIN DWH_dbo.Dim_Date dd
		ON dd.FullDate = bdcdpfd.ActiveDate

		LEFT JOIN (SELECT DATEFROMPARTS(YEAR(bdcdpfd.ActiveDate), MONTH(bdcdpfd.ActiveDate), 1)  ActiveDate
					,dd.CalendarYearQtr
					,CASE WHEN bdcdpfd.NewMarketingRegion= 'Latam' THEN 'Spain' ELSE bdcdpfd.NewMarketingRegion END NewMarketingRegion
					,COUNT(DISTINCT CASE WHEN bdcdpfd.EOD_Club NOT LIKE ('%Bronze%') AND bdcdpfd.IsFunded_New=1 THEN bdcdpfd.CID END ) ClubMember
				FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData bdcdpfd
				JOIN DWH_dbo.Dim_Date dd
				ON dd.FullDate = bdcdpfd.ActiveDate
				WHERE bdcdpfd.DateID>=20250101
				AND dd.MonthNumberOfYear IN (3,6,9,12)
				GROUP BY DATEFROMPARTS(YEAR(bdcdpfd.ActiveDate), MONTH(bdcdpfd.ActiveDate), 1) 
				,CASE WHEN bdcdpfd.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE bdcdpfd.NewMarketingRegion END 
				,dd.CalendarYearQtr) cc
		ON cc.CalendarYearQtr = dd.CalendarYearQtr
		AND cc.NewMarketingRegion = CASE WHEN bdcdpfd.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE bdcdpfd.NewMarketingRegion END 
		WHERE bdcdpfd.DateID>=20250101
		AND bdcdpfd.NewMarketingRegion <>'Unknown'
		GROUP BY DATEFROMPARTS(YEAR(bdcdpfd.ActiveDate), MONTH(bdcdpfd.ActiveDate), 1) 
				,CASE WHEN bdcdpfd.NewMarketingRegion = 'Latam' THEN 'Spain' ELSE bdcdpfd.NewMarketingRegion END 
				,dd.CalendarYearQtr
				,dd.MonthNumberOfQuarter) tt