SELECT fm.CID
	  ,fm.ActiveDate
	  ,fm.NewMarketingRegion Region
	  ,fm.Country
	  ,CASE WHEN fm.EOM_Club IN ('LowBronze','HighBronze') THEN 'Bronze' ELSE fm.EOM_Club END Club 
	  ,fm.ClusterDetail
	  ,fmc.IsNewFunded
	  ,fmc.IsChurn_NewFunded
	  ,fmc.IsWinback
          ,IsNewSeniority
          ,IsNewFundedLastMonth
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
LEFT JOIN BI_DEV.dbo.[BI_DB_CID_MonthlyPanel_Churn] fmc WITH (NOLOCK)
ON fm.ActiveDate = fmc.ActiveDate
AND fm.CID = fmc.CID
WHERE fm.ActiveDate >='2021-06-01'