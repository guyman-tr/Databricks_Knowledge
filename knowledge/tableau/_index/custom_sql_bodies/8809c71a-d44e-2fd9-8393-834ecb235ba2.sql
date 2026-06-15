SELECT r.ProcedureName
	 , r.TableName
	 , r.DateKey
	 , r.FullDate
	 , r1.ProcedureName AS ActualProc
	 , r1.ObjectStatus
	 , r1.LastDate
	 , r1.StartDate
	 , r1.DurationMin 
FROM #relevant2 r
LEFT JOIN #ran r1
	ON r.ProcedureName = r1.ProcedureName AND r.FullDate = r1.LastDate
--ORDER BY r.FullDate DESC, r.ProcedureName