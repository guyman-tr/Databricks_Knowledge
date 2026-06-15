SELECT mp.CID
		, mp.Revenue_Total
		,mp.ActiveDate
		,dc.PlayerLevelID
		,mp.TotalDeposits
		,cc.Revenue_Total Previous_Revenue_Total
		,cc.ActiveDate Previous_ActiveDate
		,cc.TotalDeposits Previous_TotalDeposits
FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN DWH.dbo.Dim_Customer dc
ON dc.RealCID=mp.CID
JOIN (
        SELECT mp1.CID
                        , mp1.Revenue_Total
                        ,mp1.ActiveDate
                        ,mp1.TotalDeposits
        FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp1
        WHERE mp1.Active_Month>=202212)
 cc
ON cc.CID = dc.RealCID
AND cc.ActiveDate = DATEADD(mm,-1,mp.ActiveDate)
WHERE mp.Active_Month>=202212
AND mp.IsFunded_New = 1