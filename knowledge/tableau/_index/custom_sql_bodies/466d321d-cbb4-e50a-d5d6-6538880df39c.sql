SELECT 
		c.from_date
		,fca.RealCID
		,CASE WHEN fca.Occurred>=from_date THEN 'After' ELSE 'Before' END Before_After
		,dat.Name action_type
		,CAST(fca.Occurred AS DATE) Occurred
		,SUM(ABS(fca.Amount)) Amount
		
FROM #CID c
 JOIN DWH_dbo.Fact_CustomerAction fca
ON fca.RealCID = c.CID
AND fca.Occurred>=DATEADD(mm,-6,from_date)
AND fca.Occurred<=DATEADD(mm,6,from_date)
 JOIN DWH_dbo.Dim_ActionType dat
ON fca.ActionTypeID = dat.ActionTypeID
AND fca.ActionTypeID IN (1,4,7,8)
GROUP BY c.from_date
		,fca.RealCID
		,CASE WHEN fca.Occurred>=from_date THEN 'After' ELSE 'Before' END 
		,CAST(fca.Occurred AS DATE) 
		,dat.Name