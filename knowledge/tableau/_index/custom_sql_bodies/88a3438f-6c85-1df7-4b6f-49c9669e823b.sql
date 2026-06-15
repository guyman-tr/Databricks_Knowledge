SELECT 
        dd.FullDate
       ,YEAR(dd.FullDate)*100+MONTH(dd.FullDate) AS YM
	   ,dc1.MarketingRegionManualName AS Region
	   ,dplm.Name AS Club
	   ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
	   ,dc.FirstDepositAmount
	   ,DATEDIFF(MONTH,bddcl.FirstDepositDate,GETDATE()-1) AS Seniority
	   ,bdkscl.Cluster AS Lead_Score
	   ,SUM(bddcl.Deposits) AS Deposits
	   ,SUM(bddcl.CashoutsAdjusted) AS CashoutsAdjusted
	   ,SUM(bddcl.Deposits)-SUM(bddcl.CashoutsAdjusted) AS Adjusted_Net_Deposits
	   ,COUNT(bddcl.CID) AS Clients
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level] bddcl WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK) ON dd.DateKey=bddcl.DateID
INNER JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON dc.RealCID=bddcl.CID AND dc.IsValidCustomer=1
INNER JOIN DWH_dbo.Dim_Country dc1  WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dplm WITH (NOLOCK) ON dc.PlayerLevelID = dplm.PlayerLevelID
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Score_CID_Level bdkscl WITH (NOLOCK) ON dc.RealCID = bdkscl.RealCID
WHERE DateID BETWEEN 20240101 AND CAST(CONVERT(VARCHAR(8), GETDATE()-1 , 112) AS INT) 
GROUP BY dd.FullDate
       ,YEAR(dd.FullDate)*100+MONTH(dd.FullDate) 
	   ,dc1.MarketingRegionManualName
	   ,dplm.Name 
	   ,CAST(dc.FirstDepositDate AS DATE) 
	   ,dc.FirstDepositAmount
	   ,DATEDIFF(MONTH,bddcl.FirstDepositDate,GETDATE()-1) 
	   ,bdkscl.Cluster