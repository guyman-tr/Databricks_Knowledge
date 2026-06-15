SELECT dc.RealCID
        ,dpl.Name PlayerLevel
		,gs.GuruStatusName GuruStatus
		,CASE WHEN dc.MifidCategorizationID IN (2,3) THEN 'Professional' ELSE 'Standard' END IsProfessional
  FROM [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
  INNER JOIN DWH.dbo.Dim_PlayerLevel dpl
  ON dc.PlayerLevelID = dpl.PlayerLevelID
  INNER JOIN DWH.dbo.Dim_GuruStatus gs
  ON dc.GuruStatusID = gs.GuruStatusID