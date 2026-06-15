SELECT a.*, dm.FirstName + ' ' + dm.LastName AS AccountManager
FROM BI_DB_Operations_Action_Triggers_Report_History a
	JOIN DWH..Dim_Customer dc
		ON a.RealCID = dc.RealCID
	JOIN DWH..Dim_Manager dm
		ON dm.ManagerID = dc.AccountManagerID
WHERE 
AlertDate = <[Parameters].[Parameter 1]>