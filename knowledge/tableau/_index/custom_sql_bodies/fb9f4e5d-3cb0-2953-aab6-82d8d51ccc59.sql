SELECT dc.RealCID
		,dc.RegisteredReal
		,bdcclp.Date ChangeLogDate
		,bdcclp.CurrentClub
		,bdcd.FirstDepositDate
		,EOMONTH(dc.RegisteredReal) EOMRegisteredReal
		,EOMONTH(bdcclp.Date) EOMClubChangeLog
		,EOMONTH(bdcd.FirstNewFundedDate) EOMFirstNewFundedDate
		,MAX(CASE WHEN bdcclp1.CurrentSort>1 THEN 1 ELSE 0 END) WasInClub
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN BI_DB_dbo.BI_DB_ClubChangeLogProduct bdcclp
ON bdcclp.CID = dc.RealCID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd
ON dc.RealCID = bdcd.CID
LEFT JOIN BI_DB_dbo.BI_DB_ClubChangeLogProduct bdcclp1
ON bdcclp1.CID = dc.RealCID
WHERE dc.AffiliateID = 83543
AND dc.RegisteredReal>='20230101'
GROUP BY dc.RealCID
		,dc.RegisteredReal
		,bdcclp.Date
		,bdcclp.CurrentClub
		,bdcd.FirstDepositDate
		,EOMONTH(dc.RegisteredReal)
		,EOMONTH(bdcclp.Date)
		,bdcd.FirstNewFundedDate