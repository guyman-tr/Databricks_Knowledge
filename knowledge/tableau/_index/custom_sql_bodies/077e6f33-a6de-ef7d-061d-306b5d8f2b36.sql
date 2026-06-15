SELECT ParentCID
	,bdcdd.UserName
	,bdcdd.PI_Level
	,bdcdd.NumOfCopiers
	, SUM(Revenue_Copy)	  Revenue_Copy
	,bdcdd.CopyAUM
    FROM [BI_DB_dbo].[BI_DB_DailyCopyRevenue] dcr  with (Nolock)
	LEFT JOIN [BI_DB_dbo].BI_DB_CopyDailyData bdcdd 
	ON bdcdd.CID=dcr.ParentCID AND bdcdd.DateID=cast(format(EOMONTH(GETDATE(),-1),'yyyyMMdd') as int)
	WHERE  dcr.DateID BETWEEN cast(format(DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0),'yyyyMMdd') as int) 
	AND  cast(format(EOMONTH(GETDATE(),-1),'yyyyMMdd') as int)
	AND bdcdd.GuruStatusID>=2
  GROUP BY ParentCID
	,bdcdd.UserName
	,bdcdd.PI_Level
	,bdcdd.NumOfCopiers
	,bdcdd.CopyAUM