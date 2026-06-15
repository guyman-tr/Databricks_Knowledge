SELECT AccountManagerID
	  ,EOMONTH(cc.Date) Date
	  ,SUM(CAST(CallDurationInSeconds AS FLOAT)) ZoomCallCallDurationInSeconds
		,COUNT(*) ZoomCallNumberOfCall
FROM 

	(SELECT bdst.CreatedById
			,bdsmu.AccountManagerID  AccountManagerID
			,CAST(bdst.CreatedDate AS DATE) Date
			,bdst.CallDuration CallDurationInSeconds
	FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
	LEFT JOIN BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Engagement bdst
	ON bdst.CreatedById = bdsmu.ID
	AND CAST(bdst.CreatedDate AS DATE)>=DATEADD(mm,-5,GETDATE())
	WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'
	AND bdst.ZoomCall = 'true'

) cc

GROUP BY 
AccountManagerID
	  ,EOMONTH(cc.Date)