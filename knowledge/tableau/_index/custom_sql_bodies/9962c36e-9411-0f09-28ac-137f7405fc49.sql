SELECT bdsce.CaseID
	  ,SUM(CASE WHEN bdsce.EventType = 'Outbound Email Message' THEN 1 ELSE 0   END) AS EventType_Outbound
	  ,SUM(CASE WHEN bdsce.EventType = 'Internal Case Comment' THEN 1 ELSE 0   END) AS EventType_Internal  	
FROM BI_DB.dbo.BI_DB_SF_Case_Event bdsce
GROUP BY  bdsce.CaseID