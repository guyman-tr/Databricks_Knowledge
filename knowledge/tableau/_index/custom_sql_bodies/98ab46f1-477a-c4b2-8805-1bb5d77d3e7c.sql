SELECT mp.ActiveDate
		,mp.EOM_Club
                ,mp.AccountManager
		,COUNT(*) Total_In_Club
		,SUM(mp.ActiveOpenWOAirdropManual) ActiveOpenWOAirdropManual
		
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
WHERE  mp.ActiveDate >= '2026-01-01'
AND mp.EOM_Club IN ('Diamond','Platinum Plus') 
GROUP BY mp.ActiveDate,mp.EOM_Club,mp.AccountManager