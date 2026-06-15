SELECT   bdcmpfd.CID
        ,bdcmpfd.Active_Month
		,bdcmpfd.ActiveDate
		,bdcmpfd.Seniority
		,dc1.Name AS Country
		,dpl.Name AS Club
		,ISNULL(b.Is_FTD_Flow,0) AS Is_FTD_Flow
		,ISNULL(d.Is_ETM,0) AS Is_ETM
		,ISNULL(b.Is_FTD_Flow,0)+ISNULL(d.Is_ETM,0) AS Flow_Test
		,CASE WHEN (ISNULL(d.Is_ETM,0)+ISNULL(b.Is_FTD_Flow,0))='11' THEN 'FTD Flow'
		      WHEN (ISNULL(d.Is_ETM,0)+ISNULL(b.Is_FTD_Flow,0))='10' THEN 'eMoney'
			  ELSE 'Not FTD Flow' END AS FTD_Flow_Category
	    ,bdcmpfd.ActiveOpen
		,bdcmpfd.Active
		,CAST (bdcmpfd.FTDdate AS DATE) AS FirstDepositDate
		,CASE WHEN dc.PlayerLevelID IN (1) THEN 'No Club'
	   	    WHEN dc.PlayerLevelID IN (3, 5) THEN 'Low Club'
	   	    WHEN dc.PlayerLevelID IN (2, 6, 7) THEN 'High Club'
	   	    WHEN dc.PlayerLevelID IN (4) THEN 'Internal'
	        ELSE 'Error' END AS 'Club Category'
	    ,bdcmpfd.ACC_Revenue_Total AS ACC_Revenue
		,bdcmpfd.ACC_TotalDeposits AS ACC_Deposits
		,bdcmpfd.ACC_CountDeposits 
		,bdcmpfd.ACC_NetDeposits
		,bdcmpfd.ACC_TotalCashouts
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd
---Is_FTD_Flow
LEFT JOIN (SELECT DISTINCT fca.RealCID AS CID,'1' AS Is_FTD_Flow
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN DWH_dbo.Dim_Customer dc ON fca.GCID = dc.GCID AND dc.IsValidCustomer=1
WHERE fca.ActionTypeID=7 AND fca.IsFTD=1 AND fca.FundingTypeID=33 AND fca.DateID>20230501
) b ON b.CID=bdcmpfd.CID
---Is_ETM
LEFT JOIN (SELECT mda.CID
	  ,'1' AS  Is_ETM
FROM eMoney_dbo.eMoney_Dim_Account mda 
WHERE mda.IsValidETM=1 AND mda.GCID_Unique_Count=1 ) d ON d.CID=bdcmpfd.CID
----
INNER JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID=bdcmpfd.CID AND dc.IsValidCustomer=1
INNER JOIN [eMoney_dbo].[eMoney_Dim_Country_Rollout] dcr WITH(NOLOCK) ON dc.CountryID = dcr.CountryID AND dcr.RolloutDateID<=20230101
INNER JOIN DWH_dbo.Dim_Country dc1 WITH(NOLOCK) ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH(NOLOCK)  ON dc.PlayerLevelID=dpl.PlayerLevelID
WHERE bdcmpfd.Active_Month>=202305  AND bdcmpfd.FTDdate>='20230501'