Select  
		 bdid.ActiveDate
		,dm.FirstName + ' ' + dm.LastName AccountManager
		,dpl.Name Club
		,bdid.IsRelevant AS Contacted
		,SUM(bdid.MoneyIn) MoneyIn
		,SUM(bdid.MoneyOut) MoneyOut
		,sa.target
		,sa.achievment
		,sa.type_of_kpi
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
OUTER APPLY(SELECT DISTINCT account_manager, type_of_kpi, month, achievment, target 
FROM [BI_DB_dbo].[External_Fivetran_google_sheet_attend] sa
WHERE sa.month=bdid.ActiveDate
AND sa.account_manager=dm.FirstName + ' ' + dm.LastName)sa
WHERE (bdcdpc.CurrentTier in (6,7) OR (dc.AccountTypeID=2 AND bdcdpc.CurrentTier NOT in (6,7)))
GROUP BY bdid.ActiveDate
		,dm.FirstName + ' ' + dm.LastName
                ,dpl.Name
				,bdid.IsRelevant
		,sa.target
		,sa.achievment
		,sa.type_of_kpi