SELECT dc1.GCID
,dc1.UserName
,dc1.Email
,dc1.RegulationID
,dl.Name AS Language
,dc.UserName as PI
,dc.GCID AS PIGCID
,dc1.ID
FROM DWH_dbo.Dim_Mirror dm
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dm.ParentCID
JOIN DWH_dbo.Dim_Customer dc1 ON dc1.RealCID=dm.CID
JOIN DWH_dbo.Dim_Language dl ON dc1.LanguageID = dl.LanguageID
WHERE dc.GuruStatusID >=5
AND dm.CloseDateID=0
AND dc1.IsValidCustomer=1
AND dc1.IsDepositor=1