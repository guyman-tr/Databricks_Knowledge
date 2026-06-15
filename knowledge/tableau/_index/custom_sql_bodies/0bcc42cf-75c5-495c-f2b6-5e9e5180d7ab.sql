SELECT b.gcid AS GCID
	 , dc.RealCID
	 ,	mn.FirstName + ' ' + mn.LastName as AccountManager
	,	c.Name Country
	,	dr.Name Regulation
	,	pl.Name Club
	 

 FROM [ThirdParty_Fivetran].[Fivetran].google_sheets.emoney_email_update_list b
			  JOIN DWH.dbo.Dim_Customer dc ON dc.GCID=b.gcid
	LEFT JOIN DWH.dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
	LEFT JOIN DWH.dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=dc.PlayerLevelID
	LEFT JOIN DWH.dbo.Dim_Country  c on dc.CountryID=c.CountryID
	LEFT JOIN DWH.dbo.Dim_Manager mn on mn.ManagerID=dc.AccountManagerID