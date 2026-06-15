Select bdid.Date
	  ,bdid.DateID
	  ,bdid.RealCID
	  ,bdid.MoneyOut
	  ,bdid.MoneyIn
	  ,bdid.AccountManagerID
	  ,bdid.CountryID
	  ,bdid.DaysContactedPhone
	  ,bdid.IsDepositor
	  ,cast (bduts.CreatedDate_SF as date) Contacted 
	  ,dm.FirstName + ' ' + dm.LastName Manager
	  ,dpl.Name Club
from  BI_DB_dbo.BI_DB_InvestorsDetail bdid
JOIN DWH_dbo.Dim_Manager dm
ON dm.ManagerID = bdid.AccountManagerID
OUTER APPLY (SELECT TOP 1 bduts.CID
					,bduts.CreatedDate_SF
					FROM BI_DB_dbo.BI_DB_UsageTracking_SF  bduts
					WHERE bduts.CID = bdid.RealCID
					AND CAST(bduts.CreatedDate_SF AS DATE)>='20230904'
					AND CAST(bduts.CreatedDate_SF AS DATE)<=bdid.Date
					AND bduts.OwnerID = dm.SFManagerID
					ORDER BY bduts.CreatedDate_SF DESC
					) bduts

JOIN DWH_dbo.Dim_Country dco
ON bdid.CountryID =dco.CountryID
JOIN DWH_dbo.Dim_Customer dc
ON bdid.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE bdid.ParentUserName = 'GainersQtr'
and ( 
		(DateID>=20231004 AND dc.PlayerLevelID>5 AND DateID<20231111)
		OR 
		(DateID>=20231009 AND dc.PlayerLevelID<6 AND DateID<20231111)
	)