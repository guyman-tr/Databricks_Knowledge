SELECT Distinct bdsmu.AccountManagerID
		,bdsmu.FirstName+' '+ bdsmu.LastName Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
	   ,cc.CallID
	   ,cc.date
	   ,cc.CallDuration
	   ,cc.ZoomCall
	   ,cc.CID
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT JOIN (SELECT CASE WHEN bdiddc.Manager LIKE 'Jigal Notoadikusumo' THEN 'Jigal Noto'
						WHEN bdiddc.Manager LIKE 'Linda Sigrist' THEN 'Linda Sigrist'
						ELSE bdiddc.Manager END Manager
				,bdiddc.CallID
				,bdiddc.CreatedDate date
				,bdiddc.CallDuration

				,bdiddc.ZoomCall
				,bdiddc.CID
			FROM BI_DB_dbo.BI_DB_Instrument_Details_During_Call bdiddc
			WHERE bdiddc.CreatedDate >= DATEADD(mm,-5,GETDATE())
			) cc
ON bdsmu.FirstName+' '+ bdsmu.LastName = cc.Manager
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'