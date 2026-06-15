SELECT 
       d.CID
      ,d.Country
	  ,d.Club
	  ,CAST (d.FirstDepositDate AS DATE) AS FirstDepositDate
	  ,d.Is_ETM
	  ,d.Seniority_FMI
	  ,d.Is_FMI
	  ,CASE WHEN d.Is_FMI+d.Is_ETM=2 THEN 'eMoney Active'
	        WHEN d.Is_FMI+d.Is_ETM =1  THEN 'eMoney'
			ELSE 'Not eMoney' END AS Tier
	  ,CASE WHEN d.Country ='United Kingdom' THEN 'UK' ELSE 'EU' END AS 'UK/EU'
	  ,CASE WHEN d.ClubID IN (1) THEN 'No Club'
	   	    WHEN d.ClubID IN (3, 5) THEN 'Low Club'
	   	    WHEN d.ClubID IN (2, 6, 7) THEN 'High Club'
	   	    WHEN d.ClubID IN (4) THEN 'Internal'
	        ELSE 'Error' END AS 'Club Category'
	  ,ISNULL(SUM(bdcmpfd.Revenue_Total),0) AS Revenue
	  ,ISNULL(SUM(bdcmpfd.TotalDeposits),0) AS 'Deposits Amount'
	  ,ISNULL(SUM(bdcmpfd.CountDeposits),0) AS 'Deposits Transactions'
	  ,ISNULL(SUM(bdcmpfd.NetDeposits),0) AS 'Net Deposits Amount'
	  ,ISNULL(SUM(bdcmpfd.TotalCashouts),0) AS 'Cashouts Transactions'
	  ,bdlba.Revenue8Y_LTV_New AS LTV
	  ,CASE WHEN ISNULL(SUM(bdcmpfd.CountDeposits),0)>0 THEN 1 ELSE 0 END AS TP_Deposits_Active
FROM (
SELECT dc.GCID
      ,dc.RealCID AS 'CID'
      ,dcr.CountryName AS 'Country'
	  ,dpl.[Name] AS 'Club'
	  ,dc.PlayerLevelID AS ClubID
	  ,dc.FirstDepositDate
	  ,CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END Is_ETM
	  ,mpfd.Seniority_FMI
	  ,CASE WHEN mpfd.FMI_Date IS NOT NULL THEN 1 ELSE 0 END Is_FMI
FROM [DWH_dbo].[Dim_Customer] dc WITH(NOLOCK)
INNER JOIN [eMoney_dbo].[eMoney_Dim_Country_Rollout] dcr WITH(NOLOCK) ON dc.CountryID = dcr.CountryID AND dcr.RolloutDateID<=20230101
INNER JOIN [DWH_dbo].[Dim_PlayerLevel] dpl WITH(NOLOCK) ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Country dc1 WITH(NOLOCK) ON dc.CountryID = dc1.CountryID AND (dc1.EU=1 OR dc1.CountryID=218)
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON dc.GCID = mda.GCID AND mda.IsValidETM=1 AND mda.GCID_Unique_Count=1
LEFT JOIN eMoney_dbo.eMoney_Panel_FirstDates mpfd WITH(NOLOCK) ON dc.GCID = mpfd.GCID
WHERE dc.IsDepositor = 1
      AND dc.IsValidCustomer = 1
	  AND dc.VerificationLevelID = 3
	  AND dc.PlayerStatusID NOT IN (2, 4, 14, 15)) d
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd WITH(NOLOCK) 
ON d.CID = bdcmpfd.CID AND bdcmpfd.Active_Month>=202401 AND bdcmpfd.Active_Month<=202612
LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba WITH(NOLOCK) ON d.CID=bdlba.CID
GROUP BY d.CID
      ,d.Country
	  ,d.Club
	  ,d.FirstDepositDate
	  ,d.FirstDepositDate
	  ,d.Is_ETM
	  ,d.Seniority_FMI
	  ,d.Is_FMI
	  ,bdlba.Revenue8Y_LTV_New
	  ,CASE WHEN d.Is_FMI+d.Is_ETM=2 THEN 'eMoney Active'
	        WHEN d.Is_FMI+d.Is_ETM=1  THEN 'eMoney'
			ELSE 'Not eMoney' END
	 ,CASE WHEN d.Country ='United Kingdom' THEN 'UK' ELSE 'EU' END
	 ,CASE WHEN d.ClubID IN (1) THEN 'No Club'
	   	    WHEN d.ClubID IN (3, 5) THEN 'Low Club'
	   	    WHEN d.ClubID IN (2, 6, 7) THEN 'High Club'
	   	    WHEN d.ClubID IN (4) THEN 'Internal'
	        ELSE 'Error' END