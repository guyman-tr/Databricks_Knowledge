SELECT TOP 30 *
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
, CASE WHEN bdcbcln.CID IN (2244852, 2283663, 2283668,5969868, 5969870, 5969875,5969866 ) THEN 1 ELSE 0 END AS IsEtoroTradingCID
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
JOIN DWH_dbo.Dim_Customer dc
ON bdcbcln.CID = dc.RealCID
WHERE bdcbcln.DateID BETWEEN 
	CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)  
	AND 
	CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)  
AND bdcbcln.IsCreditReportValidCB = 1
AND bdcbcln.Regulation IN ('CySEC','BVI')
GROUP BY CID
, dc.FirstName + ' ' + dc.LastName ,bdcbcln.YearQuarter, CASE WHEN bdcbcln.CID IN (2244852, 2283663, 2283668,5969868, 5969870, 5969875,5969866 ) THEN 1 ELSE 0 END
) a
ORDER BY 7 desc