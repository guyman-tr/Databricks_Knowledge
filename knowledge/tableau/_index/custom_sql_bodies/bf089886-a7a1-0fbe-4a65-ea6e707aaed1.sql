SELECT   fm.ActiveDate ActiveDate
        ,fm.CID CID
        ,p.PlayerLevelID PlayerLevelID
        ,fm.Revenue_Total Revenue_Total
        ,fm.TotalDeposits TotalDeposits 
		,cc.Revenue_Total Previous_Revenue_Total
		,cc.ActiveDate Previous_ActiveDate
		,cc.TotalDeposits Previous_TotalDeposits
            	,cc.CountDeposits Previous_CountDeposits
		,fm.IsFunded_New
		,fm.CountDeposits
FROM (SELECT DATEFROMPARTS(dd.CalendarYear,dd.MonthNumberOfYear,1) ActiveDate,fsc.RealCID,fsc.PlayerLevelID 
			FROM DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
			INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
			ON fsc.DateRangeID = dr.DateRangeID
			INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
			ON dr.FromDateID <=dd.DateKey
			AND dr.ToDateID >=dd.DateKey
			WHERE dd.IsLastDayOfMonth = 'Y'
			AND DateKey BETWEEN 20230101 AND 20230901
			AND IsDepositor = 1
			AND IsValidCustomer = 1
									) p
INNER JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
ON p.ActiveDate = fm.ActiveDate
AND p.RealCID = fm.CID
LEFT JOIN (
        SELECT mp1.CID
                        , mp1.Revenue_Total
                        ,mp1.ActiveDate,mp1.TotalDeposits
                        ,mp1.CountDeposits
        FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] mp1
        WHERE mp1.Active_Month>=202212) cc
ON cc.CID =fm.CID
AND cc.ActiveDate = DATEADD(mm,-1,fm.ActiveDate)
WHERE fm.ActiveDate >= '20230101'