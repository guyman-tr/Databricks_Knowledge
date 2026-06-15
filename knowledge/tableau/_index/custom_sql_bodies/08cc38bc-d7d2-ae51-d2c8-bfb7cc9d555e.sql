SELECT  bddpc.CID,bddpc.UserName,
		bddpc.NumOfCopiers,
		bddpc.CopyAUC,
		dc.FirstName, 
		dc.LastName,
		convert(date, convert(varchar(10), l.Last_Day_As_PI)) Last_Day_As_PI,
		CASE WHEN bddpc.LastBlockedDate IS NULL THEN 'No' ELSE 'Yes' END AS IsCopyBlocked,
	    bddpc.BlockReason,
		CopyType,
		Date
FROM BI_DB_DailyPanel_Copy bddpc
left jOIN DWH.dbo.Dim_Customer dc
	ON bddpc.CID=dc.RealCID
LEFT JOIN (
			SELECT  RealCID,
					MAX(dr.ToDateID) Last_Day_As_PI
			from DWH..Fact_SnapshotCustomer sc
			JOIN DWH.dbo.Dim_Range dr
				ON dr.DateRangeID = sc.DateRangeID
			WHERE sc.GuruStatusID IN (2,3,4,5,6) 
			GROUP BY RealCID
		   ) l
	ON bddpc.CID=l.RealCID
WHERE  bddpc.CopyType='RemovedPI'