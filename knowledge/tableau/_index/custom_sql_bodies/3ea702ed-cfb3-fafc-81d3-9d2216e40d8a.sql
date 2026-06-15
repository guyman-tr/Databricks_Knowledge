SELECT bdin.CID, 
	bdin.GCID, 
	bdin.ConsentStatusID, 
	bdin.ValidFrom, 
	bdin.ValidTo, 
	bdin.UpdateDate,
	dc.PlayerLevelID
FROM dbo.BI_DB_InterestConsent bdin
JOIN [DWH].[dbo].[Dim_Customer] as dc
ON bdin.CID=dc.RealCID