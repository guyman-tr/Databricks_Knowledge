SELECT --mp.FTD_Month AS FTDMonth
	  mp.FTDdate AS FirstDepositDate
	  ,mp.Seniority AS Tenure_m
	  ,mp.Active_Month AS ActiveMonth
	  ,EOMONTH(mp.ActiveDate) AS ActiveDate
	  --,fd.PotentialDesk AS Desk
	  ,dc1.MarketingRegionManualName as Region
	  ,mp.Country
	  ,CASE WHEN mp.FTDA < 50 THEN 'Less than 49'  
             WHEN mp.FTDA < 100 THEN '50-99'  
             WHEN mp.FTDA < 200 THEN '100-199'  
             WHEN mp.FTDA < 500 THEN '200-499'  
             WHEN mp.FTDA < 1000 THEN '500-1,000' 
	  	     WHEN mp.FTDA < 2500 THEN '1K-2.5K' 
             WHEN mp.FTDA >= 2500 THEN '+2.5K' END AS FTDAGroup
	  ,CASE WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<25 THEN '18-25'
	        WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<35 THEN '25-35'
	  	    WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<45 THEN '35-45'
	  	    WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())>=45 THEN '+45' END AgeGroup
	  ,mp.Channel
	  ,mp.SubChannel
	  ,mp.AffiliateID
	  --,mp.FirstAction
	  ,fa.FirstAction_Detailed
	  ,mp.FirstInstrument
	  ,fa.SecondAction
	  ,fa.SecondInstrument
	  ,fa.ThirdAction
	  ,fa.ThirdInstrument
	  --,ss.RiskGroup
	  --,ss.RiskIndex
	  --,ss.DepositGroup
	  ,SUM(mp.IsFTD_ThisM) AS FTD
	  ,SUM(mp.IsReg_ThisM) AS Leads
	  ,SUM(mp.Active) AS ActiveHold
	  ,SUM(mp.ActiveOpen)ActiveOpen
	  ,SUM(CASE WHEN mp.TotalDeposits > 0 THEN 1 ELSE 0 END) AS Depositor
	  ,SUM(mp.ActiveUser) AS Loginers
      --,EOMONTH(mp.ActiveDate) AS EndOfMonth
	  ,mp.IsOTD
	  --,da.AffiliatesGroupsName
	  ,bdk.Cluster LeadScore
	  ,COUNT(mp.CID) AS ExternalID
	  ,SUM(mp.FTDA) FTDA
	  ,SUM(mp.TotalDeposits) AS CurrentMDeposit
	  ,SUM(mp.TotalCashouts) AS CurrentMCO
      ,SUM(mp.NewTrades_Total) AS CurrentMNumOpenPos
      ,SUM(mp.AmountIn_NewTrades_Total) AS CurrentMInvAmountInNewPos
      ,SUM(mp.Revenue_Total) AS CurrentMRev
      ,SUM(mp.ACC_Revenue_Total) AS AccumulatedRev
      ,SUM(mp.ACC_TotalDeposits) AS AccumulatedDeposit
      ,SUM(mp.ACC_TotalCashouts) AS AccumulatedCO
	  ,SUM(mp.CountDeposits) AS NumOfDeposits
	  ,SUM(mp.ACC_CountDeposits) AS AccumulatedNumOfDeposits
	  ,SUM(mp.LTV_1Y) LTV_1Y
	  ,SUM(mp.LTV_3Y) LTV_3Y
	  ,SUM(mp.LTV_8Y_NoExtreme) LTV_8Y_NoExtreme
	  ,SUM(mp.LTV_8Y) LTV_8Y
	  ,SUM(mp.LTV_Expected_bySeniority) LTV_Expected_bySeniority
	  ,SUM(mp.NoExtremeLTV_Expected_bySeniority) NoExtremeLTV_Expected_bySeniority
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
LEFT JOIN #fakeftd AS f ON mp.CID = f.CID
JOIN DWH_dbo.Dim_Affiliate da ON da.AffiliateID = mp.AffiliateID
JOIN DWH_dbo.Dim_Date dd ON mp.ActiveDate = dd.FullDate
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON mp.CountryID = dc1.CountryID
left JOIN BI_DB_dbo.BI_DB_First5Actions fa ON mp.CID = fa.CID
JOIN BI_DB_dbo.BI_DB_CIDFirstDates fd ON mp.CID = fd.CID
--LEFT JOIN dbo.BI_DB_User_Segment ss ON ss.RealCID = mp.CID
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Score_CID_Level bdk ON mp.CID=bdk.RealCID
WHERE mp.ActiveDate >= '2024-01-01'
AND mp.ActiveDate < DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
and f.CID IS NULL
GROUP BY --mp.FTD_Month 
		mp.FTDdate 
		,mp.Seniority 
		,mp.Active_Month 
		,EOMONTH(mp.ActiveDate) 
		--,fd.PotentialDesk 
		,dc1.MarketingRegionManualName 
		,mp.Country
		,CASE WHEN mp.FTDA < 50 THEN 'Less than 49'  
            WHEN mp.FTDA < 100 THEN '50-99'  
            WHEN mp.FTDA < 200 THEN '100-199'  
            WHEN mp.FTDA < 500 THEN '200-499'  
            WHEN mp.FTDA < 1000 THEN '500-1,000' 
			WHEN mp.FTDA < 2500 THEN '1K-2.5K' 
            WHEN mp.FTDA >= 2500 THEN '+2.5K'  
        ELSE NULL END 
		,CASE WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<25 THEN '18-25'
		      WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<35 THEN '25-35'
			  WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())<45 THEN '35-45'
			  WHEN DATEDIFF(YEAR,fd.BirthDate,GETDATE())>=45 THEN '+45' END 
		,mp.Channel
		,mp.SubChannel
		,mp.AffiliateID
		,fa.FirstAction_Detailed
		--,mp.FirstAction
		,mp.FirstInstrument
		,fa.SecondAction
		,fa.SecondInstrument
		,fa.ThirdAction
		,fa.ThirdInstrument
		--,ss.RiskGroup
		--,ss.RiskIndex
		--,ss.DepositGroup
		--,mp.Active 
		--,mp.ActiveOpen
		,mp.ActiveUser 
      --,EOMONTH(mp.ActiveDate) 
		,mp.IsOTD
		--,da.AffiliatesGroupsName
		,bdk.Cluster