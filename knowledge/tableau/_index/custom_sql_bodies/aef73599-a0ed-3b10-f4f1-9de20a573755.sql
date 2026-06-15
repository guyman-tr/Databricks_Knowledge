SELECT
	a.*
   ,dm.FirstName + ' ' + dm.LastName AS AccountManager
   ,(SELECT count(RealCID) from BI_DB_Operations_Action_Triggers_Report where RealCID = a.RealCID ) AS TriggerCount
FROM
BI_DB_Operations_Action_Triggers_Report a
	JOIN DWH..Dim_Customer dc
		ON a.RealCID = dc.RealCID
	JOIN DWH..Dim_Manager dm
		ON dc.AccountManagerID = dm.ManagerID