SELECT a.*
	  ,b.Team
	  ,dpl.Name AS Club
      ,CASE WHEN a.Hours_from_Request <= 24 THEN '<24'
	        WHEN a.Hours_from_Request <= 48 THEN '25-48'
			WHEN a.Hours_from_Request <= 72 THEN '49-72'
			ELSE '72+' END AS Hours_from_Request_Tier
FROM (
SELECT  bw.*
       ,CASE WHEN bw.CashoutStatusID_Withdraw IN (3,4) THEN DATEDIFF(HOUR,bw.RequestDate,bw.ModificationDate)
	    ELSE DATEDIFF(HOUR,bw.RequestDate,bw.Max_UpdateDate_BillingWithdraw) END AS Hours_from_Request
FROM BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis bw WITH (NOLOCK) ) a
INNER JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON a.CID=dc.RealCID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK) ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN BI_DB_dbo.External_BI_OUTPUT_Customer_Customer_Support_Agent_User b  
ON CAST(b.AccountManagerID AS INT) = dc.AccountManagerID AND ToDate = '9999-12-31T00:00:00.000Z'