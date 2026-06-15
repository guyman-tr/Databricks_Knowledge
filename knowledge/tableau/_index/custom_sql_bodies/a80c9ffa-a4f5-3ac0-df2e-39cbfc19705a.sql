Select bdid.RealCID
		,bdid.Date ActiveDate
		,dm.FirstName + ' ' + dm.LastName AccountManager
		,dpl.Name Club
		,dat.Name AccountType
		,SUM(bdid.MoneyIn) MoneyIn
		,SUM(bdid.MoneyOut)*-1 MoneyOut
from BI_DB_dbo.BI_DB_InvestorsDetail bdid
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
WHERE bdid.InstrumentType IN ('Copy Trading','Copy Portfolio')
AND bdid.IsDepositor = 1
AND bdid.DateID>=20240701
AND bdcdpc.CurrentTier in (2,6,7)
GROUP BY bdid.Date
		,dm.FirstName + ' ' + dm.LastName
                ,dpl.Name
				,bdid.RealCID
				,dat.Name