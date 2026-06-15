Select  
		DATEFROMPARTS(YEAR(bdid.Date),MONTH(bdid.Date),1) ActiveDate
		,dm.FirstName + ' ' + dm.LastName AccountManager
		,dpl.Name Club
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
WHERE bdid.InstrumentType IN ('Copy Trading','Copy Portfolio')
AND bdid.IsDepositor = 1
AND bdid.DateID>=20240101
AND bdcdpc.CurrentTier>5
GROUP BY DATEFROMPARTS(YEAR(bdid.Date),MONTH(bdid.Date),1)
		,dm.FirstName + ' ' + dm.LastName
                ,dpl.Name