SELECT Distinct bdsmu.AccountManagerID
		,bdsmu.Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
	   ,cc.CallID
	   ,cc.date
	   ,cc.CallDuration
	   ,cc.ZoomCall
	   ,cc.CID
FROM BI_DB_SF_M_Users bdsmu
LEFT JOIN (SELECT CASE WHEN bdiddc.Manager LIKE 'Jigal Notoadikusumo' THEN 'Jigal Noto'
						WHEN bdiddc.Manager LIKE 'Linda Sigrist' THEN 'Linda Sigrist'
						ELSE bdiddc.Manager END Manager
				,bdiddc.date
				,bdiddc.CallID
				,bdiddc.CreatedDate
				,bdiddc.CallDuration

				,bdiddc.ZoomCall
				,bdiddc.CID
			FROM BI_DB_Instrument_Details_During_Call bdiddc
			WHERE bdiddc.CreatedDate >= DATEADD(mm,-5,GETDATE())
			) cc
ON bdsmu.Name = cc.Manager
WHERE bdsmu.ToDate = '9999-12-31'