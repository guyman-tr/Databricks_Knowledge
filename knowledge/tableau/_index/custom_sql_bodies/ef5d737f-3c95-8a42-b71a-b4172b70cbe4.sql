SELECT dc.RealCID
		,dc.FirstName + ' ' + dc.LastName FullName
		,dc.Email
		,dc.Phone
		,DATEDIFF(dd,dc.RegisteredReal,GETDATE()) Days_From_Reg
		,bdcd.LastLoggedIn
		,COUNT(bdscp.TicketID) Active_Cases
FROM DWH_dbo.Dim_Customer dc
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd
ON dc.RealCID = bdcd.CID
LEFT JOIN BI_DB_dbo.BI_DB_SF_Cases_Panel bdscp
ON dc.RealCID = bdscp.CID_Last
WHERE dc.IsValidCustomer = 1
AND dc.VerificationLevelID = 3
AND dc.RegisteredReal>=DATEADD(dd,-15,GETDATE())
AND dc.IsDepositor = 0
GROUP BY dc.RealCID
		,dc.FirstName + ' ' + dc.LastName 
		,dc.Email
		,dc.Phone
		,DATEDIFF(dd,dc.RegisteredReal,GETDATE()) 
		,bdcd.LastLoggedIn