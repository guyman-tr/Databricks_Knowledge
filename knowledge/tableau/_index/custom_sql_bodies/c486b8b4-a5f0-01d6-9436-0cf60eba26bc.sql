SELECT bdsmu.AccountManagerID
		,bdsmu.FirstName+' '+bdsmu.LastName Name
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionName
		,bdsmu.ID
                ,EOMONTH(cast(bduts.CreatedDate_SF as Date)) EOMONTH
	  ,cast(bduts.CreatedDate_SF as Date) Date
	,cast(convert(varchar(8),bduts.CreatedDate_SF,112) as int) DateID 
        ,count(*) NumOfCall
	,COUNT(DISTINCT bduts.CID) UniqueCID
FROM BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT JOIN BI_DB_dbo.BI_DB_UsageTracking_SF bduts
ON bduts.CreatedByID = bdsmu.ID--ON bduts.ManagerID = CAST(bdsmu.AccountManagerID AS INT)
AND cast(bduts.CreatedDate_SF as Date)>=DATEADD(mm,-5,GETDATE())
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'
group by bdsmu.AccountManagerID
		,bdsmu.FirstName+' '+bdsmu.LastName 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionName
		,bdsmu.ID
                ,EOMONTH(cast(bduts.CreatedDate_SF as Date))
	  ,cast(bduts.CreatedDate_SF as Date) 
	,cast(convert(varchar(8),bduts.CreatedDate_SF,112) as int)