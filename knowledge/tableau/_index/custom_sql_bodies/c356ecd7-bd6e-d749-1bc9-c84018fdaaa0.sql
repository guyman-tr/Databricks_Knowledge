SELECT m.ProcedureName
--	 , osh.ProcedureName
	 , osh.ObjectStatus
	 , cast(osh.LastDate as Date) as LastDate
	 , osh.RN, CASE WHEN osh.ObjectStatus <> 2 THEN 0 ELSE 1 END AS Success 
FROM #mostrelevant m
LEFT JOIN 
		(SELECT ProcedureName, ObjectStatus, LastDate, ROW_NUMBER () OVER (PARTITION BY ProcedureName, cast(LastDate AS Date) ORDER BY LastDate DESC) AS RN
		FROM ObjectsStatusHistory 
		) osh
	ON m.ProcedureName = osh.ProcedureName AND cast(osh.LastDate AS DATE) >= dateadd(MONTH,-1,getdate()-1) AND osh.RN = 1