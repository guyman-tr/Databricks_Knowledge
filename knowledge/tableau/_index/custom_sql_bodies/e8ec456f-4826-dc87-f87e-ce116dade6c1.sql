SELECT 
	bw.CID 
	--,SUM([CO Amount]) AS [CO Amount], 
	--CASE WHEN SUM(bw.[CO Amount])>=50000 AND SUM(bw.[CO Amount])<100000 THEN '50K TO 100K' 
	--	WHEN SUM(bw.[CO Amount])>=100000 AND SUM(bw.[CO Amount])<250000 THEN '100K to 250k'
	--	WHEN SUM(bw.[CO Amount])>=250000 THEN '>250K' END as Category
	--	,RequestDate
		,dm.FirstName + ' ' + dm.LastName  'AccountManager'
		FROM (
SELECT 
	DISTINCT WithdrawID,
	CAST(bw.RequestDate AS DATE) AS RequestDate,
	bw.CID, 
	bw.[Amount_Withdraw] AS [CO Amount]

FROM [DWH_dbo].[Fact_BillingWithdraw] bw  WITH (NOLOCK)
WHERE  CAST(bw.RequestDate AS DATE)>='20240520'
AND bw.FundingTypeID_Withdraw  NOT IN (27) AND  
bw.CashoutStatusID_Withdraw     IN (4)
)bw
JOIN [BI_DB_dbo].[BI_DB_UsageTracking_SF] ut WITH (NOLOCK)
ON ut.CID= bw.CID 
AND CreatedDate_SF>= RequestDate AND CreatedDate_SF<=DATEADD(day, 3, RequestDate)
AND ActionName IN ('Phone_Call_Succeed__c')
JOIN DWH_dbo.Dim_Customer c 
ON c.RealCID=bw.CID
LEFT JOIN DWH_dbo.Dim_Manager dm 
ON dm.ManagerID=c.AccountManagerID
GROUP BY 
bw.CID,RequestDate	,dm.FirstName + ' ' + dm.LastName 
HAVING SUM(bw.[CO Amount])>=50000