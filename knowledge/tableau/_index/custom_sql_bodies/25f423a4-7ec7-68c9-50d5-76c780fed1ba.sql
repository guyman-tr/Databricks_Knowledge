SELECT AccountManagerID
	  ,EOMONTH(cc.Date) Date
	  ,SUM(cc.WhatsApp) WhatsApp 
	  ,SUM(CallDurationInSeconds) CallDurationInSeconds
		,COUNT(*) NumberOfCall
FROM 

	(SELECT bdst.Id
			,max(bdsmu.AccountManagerID)  AccountManagerID
			,max(CAST(bdst.CreatedDateTime AS DATE)) Date
			,max(bdst.CallDurationInSeconds) CallDurationInSeconds
			,SUM(CASE WHEN bdst.Subject='Completed WhatsApp Session' THEN 1 ELSE 0 END) WhatsApp

	FROM BI_DB_SF_M_Users bdsmu
	LEFT JOIN BI_DB_SF_Task bdst
	ON bdst.OwnerId = bdsmu.Id
	AND bdst.CreatedDateTime>=DATEADD(mm,-5,GETDATE())
	WHERE bdsmu.ToDate = '9999-12-31'
	GROUP BY 
	bdst.Id) cc
GROUP BY 
AccountManagerID
	  ,EOMONTH(cc.Date)