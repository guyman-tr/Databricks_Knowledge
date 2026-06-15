SELECT CAST(nps.GCID AS int)GCID
      ,nps.NPSScore
	  ,dc1.Desk
	  ,dc1.MarketingRegionManualName Region
	  ,dpl.Name Club
	  ,dc.FirstDepositDate
	  ,nps.YearMonth
	  ,CONVERT(DATETIME,CAST(nps.SubmitDate AS VARCHAR),112) SubmitDate
	  ,bdcdc.ClusterDetail
FROM  BI_DEV..BI_DEV_Churn_NPS nps
JOIN DWH..Dim_Customer dc
	ON nps.GCID = dc.GCID
JOIN DWH..Dim_PlayerLevel dpl
	ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH..Dim_Country dc1
	ON dc.CountryID = dc1.CountryID
LEFT JOIN BI_DB..BI_DB_CID_DailyCluster bdcdc
	ON bdcdc.CID = dc.RealCID
	AND nps.SubmitDate BETWEEN bdcdc.FromDateID AND bdcdc.ToDateID