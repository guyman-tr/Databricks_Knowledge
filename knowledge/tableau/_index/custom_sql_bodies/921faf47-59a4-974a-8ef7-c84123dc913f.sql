SELECT dm.CID
	,ParentCID
	,ParentUserName
	,OpenOccurred
	,CloseOccurred
	,CloseDateID
	,gs.GuruStatusName GuruStatus
	FROM DWH_dbo.Dim_Mirror dm
	INNER JOIN
	(SELECT CID
	,MIN(MirrorID) MirrorID
	FROM DWH_dbo.Dim_Mirror dm
	INNER JOIN DWH_dbo.Dim_Customer dc
	ON dc.RealCID=dm.CID 
	WHERE dc.IsValidCustomer=1
	GROUP BY CID) f
	ON dm.MirrorID=f.MirrorID
	INNER JOIN DWH_dbo.Dim_Customer dc 
	ON dc.RealCID=dm.ParentCID
	INNER JOIN DWH_dbo.Dim_GuruStatus gs WITH (NOLOCK)
	ON gs.GuruStatusID = dc.GuruStatusID 
	WHERE dc.GuruStatusID >=2
	AND dc.IsValidCustomer = 1