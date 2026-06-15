Select  bdcdpc.CID
		,dpl.Name Club
		,dm.FirstName + ' ' + dm.LastName AM
		,bdcdpc.RealizedEquity
		,bdcdpc.RealizedEquityNoCFD
		,bdcdpc.RealizedEquityClub ClubEquity
		,bdcdpc.eMoneyBalance
		,bdcdpc.Moneyfarm
		,dc.MarketingRegionManualName Region
		,bdcdpc.CurrentTier
                ,bdcdpc.Date
from BI_DB_dbo.BI_DB_CID_DailyPanel_Club bdcdpc
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON bdcdpc.CurrentTier = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Manager dm
ON dm.ManagerID = bdcdpc.AccountManagerID
JOIN DWH_dbo.Dim_Country dc
ON bdcdpc.CountryID = dc.CountryID
WHERE  (SELECT MAX(DateID) DateID FROM BI_DB_dbo.BI_DB_CID_DailyPanel_Club) = bdcdpc.DateID
--WHERE  DATEADD(dd,-1,GETDATE()) = bdcdpc.Date
and bdcdpc.CurrentTier>1