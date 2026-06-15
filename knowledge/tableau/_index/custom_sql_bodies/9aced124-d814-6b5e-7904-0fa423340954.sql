SELECT dc.RealCID ParentCID
,dc.UserName
,dc.GuruStatusID 
,gs.GuruStatusName GuruStatus		
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_GuruStatus gs WITH (NOLOCK)
	ON gs.GuruStatusID = dc.GuruStatusID
WHERE dc.GuruStatusID >= 2
	AND dc.IsValidCustomer = 1