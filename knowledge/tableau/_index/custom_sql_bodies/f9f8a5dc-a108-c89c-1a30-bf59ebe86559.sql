SELECT mp.ActiveDate
		,mp.EOM_Club
                ,mp.AccountManager
		,COUNT(*) Total_In_Club
		,SUM(mp.ActiveOpenWOAirdropManual) ActiveOpenWOAirdropManual
		
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
WHERE  mp.ActiveDate >= '20230701'
GROUP BY mp.ActiveDate,mp.EOM_Club,mp.AccountManager