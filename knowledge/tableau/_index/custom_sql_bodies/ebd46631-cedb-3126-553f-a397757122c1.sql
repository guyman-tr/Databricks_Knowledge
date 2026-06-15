SELECT mp.CID
		, mp.Revenue_Total
		,mp.ActiveDate
		,dc.PlayerLevelID
		,mp.TotalDeposits
FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN DWH.dbo.Dim_Customer dc
ON dc.RealCID=mp.CID
WHERE mp.Active_Month>=202212
AND dc.IsValidCustomer=1