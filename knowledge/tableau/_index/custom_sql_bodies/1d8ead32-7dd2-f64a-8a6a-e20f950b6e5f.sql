Select   bdid.RealCID
		 ,bdid.ActiveDate
            ,bdid.Date
		,dm.FirstName + ' ' + dm.LastName AccountManager
		,dpl.Name Club
		,dat.Name AccountType
		,bdid.IsRelevant AS Contacted
		,SUM(bdid.MoneyIn) MoneyIn
		,SUM(bdid.MoneyOut) MoneyOut
from #Full_Mon bdid
LEFT JOIN BI_DB_dbo.BI_DB_CID_DailyPanel_Club bdcdpc
ON bdcdpc.CID = bdid.RealCID
AND bdcdpc.DateID = bdid.DateID
LEFT JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dpl.PlayerLevelID = bdcdpc.CurrentTier
JOIN DWH_dbo.Dim_Country dco
ON bdid.CountryID = dco.CountryID
JOIN DWH_dbo.Dim_Manager dm
ON dm.ManagerID = bdid.AccountManagerID
JOIN DWH_dbo.Dim_Customer dc
ON bdid.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_AccountType dat
ON dc.AccountTypeID = dat.AccountTypeID
AND (bdcdpc.CurrentTier in (6,7) OR dc.AccountTypeID=2 AND bdcdpc.CurrentTier NOT in (6,7))
GROUP BY  bdid.RealCID
		,bdid.ActiveDate
                   ,bdid.Date
		,dm.FirstName + ' ' + dm.LastName
                ,dpl.Name
				,dat.Name
				,bdid.IsRelevant