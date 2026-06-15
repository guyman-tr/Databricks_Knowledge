SELECT TOP 10 *
FROM 
(
SELECT 
	bdcbcln.YearQuarter
	,bdcbcln.CID
	, dc.FirstName + ' ' + dc.LastName AS Name
	, SUM(bdcbcln.ClientBalanceFullCommission) ClientBalanceFullCommission
	, SUM(bdcbcln.UnrealizedFullCommissionChange) UnrealizedFullCommissionChange
	, ISNULL(SUM(bdcbcln.OvernightFee),0) - ISNULL(SUM(bdcbcln.DividendsPaid),0) AS TotalOvernightExDividend
	, ABS(ISNULL(SUM(bdcbcln.ClientBalanceFullCommission),0) + ISNULL(SUM(bdcbcln.UnrealizedFullCommissionChange),0) + ISNULL(SUM(bdcbcln.OvernightFee),0) - ISNULL(SUM(bdcbcln.DividendsPaid),0)) AS TotalAbsCommissions
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
	JOIN DWH_dbo.Dim_Customer dc
		ON bdcbcln.CID = dc.RealCID
WHERE bdcbcln.DateID BETWEEN CAST(CONVERT(VARCHAR(8), DATEADD(qq, DATEDIFF(qq, 0, <[Parameters].[Parameter 1]>), 0), 112) AS INT)  AND CAST(CONVERT(VARCHAR(8), DATEADD(qq, DATEDIFF(qq, 0, <[Parameters].[FromDate (copy)_2312879933874958337]>), 0), 112) AS INT) 
AND bdcbcln.IsCreditReportValidCB = 1
AND bdcbcln.Regulation IN ('CySEC','BVI')
GROUP BY CID
	, dc.FirstName + ' ' + dc.LastName ,bdcbcln.YearQuarter
) a