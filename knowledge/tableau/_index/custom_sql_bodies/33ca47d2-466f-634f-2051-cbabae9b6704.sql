SELECT  dc.GuruStatusID
	,dc.UserName
	,CASE WHEN dc.AccountTypeID=9 THEN 'CopyPortfolio' ELSE 'CopyTrade' END AS Type
,SUM(dcr.Revenue_Real_Stocks) Real_Stocks
,SUM(dcr.Revenue_CFD_Stocks) CFD_Stocks
,SUM(dcr.Revenue_Real_Crypto) Real_Crypto
,SUM(dcr.Revenue_CFD_Crypto) CFD_Crypto
,SUM(dcr.Revenue_FX) FX
,SUM(dcr.Revenue_Comm) Comm
,SUM(dcr.Revenue_Ind) Ind
,SUM(dcr.Revenue_Copy)  Total
FROM [BI_DB_dbo].[BI_DB_DailyCopyRevenue] dcr 
 JOIN DWH_dbo.Dim_Customer dc
ON dc.RealCID=dcr.ParentCID
WHERE  dcr.DateID BETWEEN cast(format(DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0),'yyyyMMdd') as int) 
	AND  cast(format(EOMONTH(GETDATE(),-1),'yyyyMMdd') as int)
GROUP BY dc.UserName,dc.GuruStatusID,CASE WHEN dc.AccountTypeID=9 THEN 'CopyPortfolio' ELSE 'CopyTrade' END