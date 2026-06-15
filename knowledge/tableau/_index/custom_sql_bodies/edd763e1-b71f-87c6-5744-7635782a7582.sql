SELECT mp.CID

		,mp.EOM_Club
		,mp.ActiveDate
		,dc.Gender
		,mp.ActiveUser
		,mp.Active
		,mp.ActiveOpen
		,mp.FTDdate
		,mp.FTDA
		,mp.Region
		,mp.Country
		,mp.IsFunded_New
		,mp.IsFTD_ThisM
FROM BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN DWH.dbo.Dim_Customer dc
ON dc.RealCID = mp.CID
WHERE mp.ActiveDate>=DATEADD(MONTH,-6,GETDATE())