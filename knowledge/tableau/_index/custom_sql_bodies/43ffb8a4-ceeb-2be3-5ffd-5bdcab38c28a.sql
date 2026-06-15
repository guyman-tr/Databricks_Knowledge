SELECT DATEFROMPARTS(YEAR(Date),MONTH(Date),1) AS 'Month',
dc.GuruStatusID
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
WHERE  dcr.DateID BETWEEN cast(format(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()-1) - 2, 0),'yyyyMMdd') as int) 
	AND  cast(format(EOMONTH(DATEADD(MONTH, -1, GETDATE()-1)),'yyyyMMdd') as int)
GROUP BY DATEFROMPARTS(YEAR(Date),MONTH(Date),1),dc.UserName,dc.GuruStatusID,CASE WHEN dc.AccountTypeID=9 THEN 'CopyPortfolio' ELSE 'CopyTrade' END