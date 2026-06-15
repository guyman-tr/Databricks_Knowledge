SELECT AccountManagerID
	  ,EOMONTH(cc.Date) Date
	  ,SUM(cc.WhatsApp) WhatsApp 
	  ,SUM(cc.CallDurationInSeconds) CallDurationInSeconds
		,COUNT(*) NumberOfCall
FROM 

	(SELECT bdst.Id
			,max(bdsmu.AccountManagerID)  AccountManagerID
			,max(CAST(bdst.CreatedDateTime AS DATE)) Date
			,max(cast (bdst.CallDurationInSeconds AS INT)) CallDurationInSeconds
			,MAX(CASE WHEN bdst.Subject='Completed WhatsApp Session' THEN 1 ELSE 0 END) WhatsApp

	FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
	LEFT JOIN BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Task bdst
	ON bdst.OwnerId = bdsmu.ID
	AND CAST(bdst.CreatedDateTime AS DATE)>=DATEADD(mm,-5,GETDATE())
	WHERE bdsmu.ToDate =  '9999-12-31T00:00:00.000Z'
	GROUP BY 
	bdst.Id) cc
GROUP BY 
AccountManagerID
	  ,EOMONTH(cc.Date)