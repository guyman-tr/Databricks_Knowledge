SELECT bdsmu.AccountManagerID
		,bdsmu.Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionName
		,bdsmu.Id
                ,EOMONTH(bduts.CreatedDate_SF) EOMONTH
	  ,cast(bduts.CreatedDate_SF as Date) Date
	,cast(convert(varchar(8),bduts.CreatedDate_SF,112) as int) DateID 
        ,count(*) NumOfCall
FROM BI_DB_SF_M_Users bdsmu
LEFT JOIN BI_DB_UsageTracking_SF bduts
ON bduts.ManagerID = CAST(bdsmu.AccountManagerID AS INT)
AND bduts.CreatedDate_SF>=DATEADD(mm,-5,GETDATE())
WHERE bdsmu.ToDate = '9999-12-31'
group by bdsmu.AccountManagerID
		,bdsmu.Name 
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionName
		,bdsmu.Id
                ,EOMONTH(bduts.CreatedDate_SF)
	  ,cast(bduts.CreatedDate_SF as Date) 
	,cast(convert(varchar(8),bduts.CreatedDate_SF,112) as int)