Select  bdcdpc.CID
		,dpl.Name Club
		,dm.FirstName + ' ' + dm.LastName AM
		,bdcdpc.RealizedEquity
		,bdcdpc.RealizedEquityNoCFD
		,bdcdpc.RealizedEquityClub ClubEquity
		,bdcdpc.eMoneyBalance
		,bdcdpc.Moneyfarm
		,isnull(cc.InitialAmountCents,0) 'CFD_positionX2+'
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
LEFT JOIN (SELECT dp.CID
					,SUM(dp.InitialAmountCents)/100  InitialAmountCents
					FROM  DWH_dbo.Dim_Position dp
			WHERE dp.CloseDateID = 0
			AND dp.Leverage>1
			GROUP BY dp.CID) cc
ON bdcdpc.CID = cc.CID
WHERE  (SELECT MAX(DateID) DateID FROM BI_DB_dbo.BI_DB_CID_DailyPanel_Club) = bdcdpc.DateID
--WHERE  DATEADD(dd,-1,GETDATE()) = bdcdpc.Date
and bdcdpc.CurrentTier>1