SELECT bdsmu.AccountManagerID
		,bdsmu.FirstName +' '+ LastName AS Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,CASE WHEN bduts.ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c') THEN 'Contacted' ELSE 'Attempted' END ActionName
		,bdsmu.ID AS Id
        ,CAST(bduts.CreatedDate_SF AS DATE) Date 
	,bduts.CreatedDate_SF DateTime
        ,bduts.CreatedDate_SF MaxDate
	,bduts.CreatedDate_SF MINDate
	,cast(convert(varchar(8),bduts.CreatedDate_SF,112) as int) DateID 
        ,CID
        ,bduts.ID CsllID
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT JOIN BI_DB_dbo.BI_DB_UsageTracking_SF bduts
ON bduts.CreatedByID = bdsmu.ID
AND bduts.CreatedDate_SF>=DATEADD(mm,-5,GETDATE())
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'