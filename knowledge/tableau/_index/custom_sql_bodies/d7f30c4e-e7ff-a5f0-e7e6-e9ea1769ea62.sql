SELECT
	ah.AlertCategory
   ,ah.AlertType
   ,ah.CID
   ,ah.Name
   ,ah.Country
   ,ah.AccountType
   ,ah.Regulation
   ,CAST(MAX(ah.AlertDate) AS DATE) AS LastAlert
   ,CAST(MIN(ah.AlertDate) AS DATE) AS FirstAlert
   ,COUNT(CID) AS [CID Similar Alert Count]
   ,(SELECT COUNT(CID) FROM BI_DB_AML_Daily_Alerts_History WHERE CID = ah.CID GROUP BY CID) AS [Total Alerts Per CID]
   ,MAX(CASE WHEN ah.AlertStatus = 'Done' THEN 1 ELSE 0 END) AS [Was Handled]
   ,MAX(CASE WHEN ah.AlertStatus = 'Done' THEN ah.AlertDate ELSE '1900-01-01' END) AS [Last Handled]
FROM BI_DB_AML_Daily_Alerts_History ah
WHERE ah.AlertCategory IS NOT null
GROUP BY 	
	ah.AlertCategory
   ,ah.AlertType
   ,ah.CID
   ,ah.Name
   ,ah.Country
   ,ah.AccountType
,ah.Regulation