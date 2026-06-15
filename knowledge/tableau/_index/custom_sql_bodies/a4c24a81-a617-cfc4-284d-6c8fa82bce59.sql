SELECT ac.*
		,bdfa.FirstInstrument
		,bdcd.SerialID
		,bdcd.Region
		,dc.SubChannelID
		,dc.SubChannel
		,dc.Channel
		,CASE WHEN ParentUserName = bdfa.FirstInstrument THEN 1 ELSE 0 END AS IsFirstAction
FROM ( SELECT DC.RealCID, 
		Occurred, 
		ROW_NUMBER() OVER (PARTITION BY DC.RealCID ORDER BY Occurred) AS [rank], 
		ActionTypeID, 
		FCA.MirrorID, 
		HM.ParentCID, 
		HM.ParentUserName,
		FCA.Amount*-1 AS Amount
	FROM  BI_DB_dbo.BI_DB_CIDFirstDates FD with (NOLOCK)
		JOIN DWH_dbo.Dim_Customer DC  with (NOLOCK)
			ON FD.CID = DC.RealCID 
			AND DC.PlayerLevelID <> 4
			AND DC.IsValidCustomer = 1
			AND  DC.IsDepositor = 1
		 JOIN DWH_dbo.Fact_CustomerAction FCA with (NOLOCK)
			ON DC.RealCID = FCA.RealCID
			AND ActionTypeID in (17)
		 JOIN DWH_dbo.Dim_Mirror HM  with (NOLOCK)
			ON FCA.MirrorID = HM.MirrorID  
		 JOIN (SELECT RealCID AS CID, 
						UserName 
			FROM DWH_dbo.Dim_Customer with (NOLOCK)
			WHERE (AccountTypeID = 9 and RegisteredReal >'2016-01-01') OR RealCID IN (4657450 , 4657433, 4657429, 4657444, 4657439, 4657462)) CF
		ON CF.CID = HM.ParentCID
		) ac
JOIN BI_DB_dbo.BI_DB_First5Actions bdfa
	ON ac.RealCID = bdfa.CID
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd
	ON ac.RealCID = bdcd.CID
JOIN DWH_dbo.Dim_Affiliate da
	ON bdcd.SerialID = da.AffiliateID
JOIN DWH_dbo.Dim_Channel dc
	ON da.SubChannelID = dc.SubChannelID
WHERE [rank] =1