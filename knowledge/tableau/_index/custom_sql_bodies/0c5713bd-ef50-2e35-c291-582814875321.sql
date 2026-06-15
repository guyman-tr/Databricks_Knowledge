SELECT dc.GCID,dc.RealCID AS CID
      ,sub.AccountManager
	  ,CASE WHEN dc.GCID LIKE '%[0123]' THEN 'Test' ELSE 'Control' END AS Segment
	  ,c.Last_contact
      ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
	  ,CAST(dc.RegisteredReal AS DATE) AS RegDate
	  ,dpl.Name AS Club
	  ,dc1.Name AS Country
	  ,b.Crypto_revenue_2023
	  ,b.Revenue_2023
	  ,sub.ACC_CountDeposits
	  ,sub.Active_Month
	  ,sub.LastPosOpenDate
	  ,sub.ACC_Revenue_Total
	  ,sub.ACC_Revenue_Crypto
	  ,sub.ACC_TotalDeposits
	  ,sub.EOM_Equity AS Equity
	  ,CASE WHEN sub.ACC_Revenue_Total =0 THEN 1 ELSE 0 END AS '0 ACC Revenue'
	  ,CASE WHEN sub.ACC_Revenue_Crypto =0 THEN 1 ELSE 0 END AS '0 ACC Crypto Revenue'
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)
INNER JOIN 
(SELECT bddcr.CountryID
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr WITH (NOLOCK)
WHERE bddcr.DateID>20230101
GROUP BY bddcr.CountryID
HAVING SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)>0
)a ON dc.CountryID=a.CountryID
LEFT JOIN 
(SELECT bddcr.RealCID
       ,SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Crypto_revenue_2023
	   ,SUM( bddcr.FullCommissions +bddcr.RollOverFee ) AS Revenue_2023
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr WITH (NOLOCK)
WHERE bddcr.DateID>20230101
GROUP BY bddcr.RealCID
HAVING SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)>0
) b ON dc.RealCID=b.RealCID
LEFT JOIN (
SELECT  bdcmpfd.CID
       ,bdcmpfd.AccountManager
       ,bdcmpfd.Active_Month
	   ,bdcmpfd.ActiveDate
	   ,bdcmpfd.LastPosOpenDate
	   ,bdcmpfd.ACC_Revenue_Total
	   ,bdcmpfd.ACC_Revenue_Real_Crypto+bdcmpfd.ACC_Revenue_CFD_Crypto AS ACC_Revenue_Crypto
	   ,bdcmpfd.EOM_Equity
	   ,bdcmpfd.ACC_TotalDeposits
	   ,bdcmpfd.ACC_CountDeposits
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd) sub ON dc.RealCID=sub.CID AND sub.ActiveDate=DATEADD(Month,DATEDIFF(Month,0,GETDATE ()-1),0)
LEFT JOIN (
SELECT  bduts.CID
       ,MAX(CAST(bduts.CreatedDate AS DATE)) AS Last_contact
FROM BI_DB_dbo.BI_DB_UsageTracking_SF bduts WITH (NOLOCK)
WHERE bduts.ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') AND bduts.CreatedDate>='20231201' 
GROUP BY bduts.CID)c ON c.CID=dc.RealCID
INNER JOIN DWH_dbo.Dim_Country dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK) ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE  (dc.GCID LIKE '%[0123]' OR  dc.GCID LIKE '%[456789]')
AND dc.IsValidCustomer=1 
AND dc.RegisteredReal>='20211101' 
AND dc.RegisteredReal<'20231101' 
--AND dc.VerificationLevelID=3
--AND (dc.FirstDepositDate ='1900-01-01 00:00:00.000' OR dc.FirstDepositDate>='20231201')
AND dc.FirstDepositDate>='20231201'