SELECT fsc.RealCID CID
       ,dc.UserName
	   ,CAST(dc.RegisteredReal AS DATE) RegistrationDate
	   ,dpl.Name Club
	   ,CASE WHEN dc.FirstDepositDate = '19000101' THEN NULL ELSE CAST(dc.FirstDepositDate AS DATE) END FTDDate
	   ,dc1.Region Region
	   ,dc1.Name Country
	   ,ISNULL(fm.ACC_NetDeposits,0)   NetDeposit
	   ,ISNULL(fm.ACC_Revenue_Total,0) Revenue
	   ,ISNULL(fm.ACC_PnL_Copy,0)      PnL
	   ,ISNULL(dc.FirstDepositAmount,0) FTDA
	   ,dr.Name    Regulation
       ,MIN(CAST(CAST(dr1.FromDateID As CHAR(8)) AS DATE)) ApprovalDate
	   ,fm.ClusterDetail 
	   ,vl.RealizedEquity
FROM DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Range dr1 WITH (NOLOCK)
ON fsc.DateRangeID = dr1.DateRangeID
INNER JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK)
ON fsc.RealCID = dc.RealCID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Country dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_Regulation dr WITH (NOLOCK)
ON dc.RegulationID = dr.ID
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData fm WITH (NOLOCK)
ON fsc.RealCID = fm.CID
AND fm.ActiveDate = DATEFROMPARTS(YEAR(getdate()-1),MONTH(getdate()-1),1)
Left JOIN DWH_dbo.V_Liabilities vl
ON fsc.RealCID = vl.CID
AND vl.FullDate = CAST(DATEADD(dd,-2,GETDATE()) AS DATE)
WHERE fsc.AccountTypeID = 2
GROUP BY fsc.RealCID
       ,dc.UserName
	   ,CAST(dc.RegisteredReal AS DATE) 
	   ,dpl.Name 
	   ,CASE WHEN dc.FirstDepositDate = '19000101' THEN NULL ELSE CAST(dc.FirstDepositDate AS DATE) END
	   ,dc1.Region 
	   ,dc1.Name 
	   ,ISNULL(fm.ACC_NetDeposits,0)   
	   ,ISNULL(fm.ACC_Revenue_Total,0) 
	   ,ISNULL(fm.ACC_PnL_Copy,0)
	   ,ISNULL(dc.FirstDepositAmount,0) 
	   ,dr.Name  
	   ,fm.ClusterDetail
	   ,vl.RealizedEquity