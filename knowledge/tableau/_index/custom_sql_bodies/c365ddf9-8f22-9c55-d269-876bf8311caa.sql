SELECT c.*
      ,(CASE WHEN c.Equity_for_CO_Ratio <> 0 AND c.AdjustedCO>0 THEN c.AdjustedCO / c.Equity_for_CO_Ratio ELSE NULL END) AS Ratio
	  ,AVG(CASE WHEN c.Equity_for_CO_Ratio <> 0 AND c.AdjustedCO>0 THEN c.AdjustedCO / c.Equity_for_CO_Ratio ELSE NULL END)
        OVER (PARTITION BY c.CID,c.WeekStart) AS AvgRatioPerIDDay   
	,CASE WHEN c.FirstCashoutDate IS NULL THEN 'No CO'  
	      WHEN (CAST(c.FirstCashoutDate AS DATE) = c.Date AND c.Is_CO=1) THEN 'First CO' 
		  ELSE 'Recurring CO' END AS CO_Count
FROM (
SELECT  bdvddp.Date 
  , bdvddp.RealCID AS CID
  , bdvddp.UpdateDate
  , dc1.MarketingRegionManualName Region
  , dpl.Name Club
  , dc1.Name Country
  , bdcdc.ClusterDetail
  , bdcd.FirstCashoutDate
  , m.RealizedEquity AS RealizedEquity_Day_Before
  , CASE 
        WHEN (m.RealizedEquity < (bdvddp.TPCashoutsOldDef - bdvddp.TransferCoins - bdvddp.CashoutAdjustment)) 
             AND bdvddp.RealizedEquityTP = 0 
        THEN (bdvddp.TPCashoutsOldDef - bdvddp.TransferCoins - bdvddp.CashoutAdjustment)
        ELSE ISNULL(m.RealizedEquity,bdvddp.RealizedEquityTP)+bdvddp.TPDepositsOldDef
    END AS Equity_for_CO_Ratio
  --, ISNULL(m.RealizedEquity,bdvddp.RealizedEquityTP) AS Equity_for_CO_Ratio
  , CAST(bdvddp.WeekStart AS DATE) AS WeekStart
  , CAST(dc.FirstDepositDate AS DATE) AS FTD_Date
  , bdvddp.RealizedEquityTP
  , bdvddp.InternalWithdrawTPAmount AS IBAN_CO
  , bdvddp.TPDepositsOldDef
  , bdvddp.TPCashoutsOldDef TPCashoutsOldDef
  , bdvddp.TransferCoins TransferCoins
  , bdvddp.CashoutAdjustment CashoutAdjustment
  , bdvddp.TPCashoutsOldDef - bdvddp.TransferCoins - bdvddp.CashoutAdjustment  AdjustedCO
  , bdvddp.TPDepositsOldDef -  bdvddp.TPCashoutsOldDef - bdvddp.TransferCoins - bdvddp.CashoutAdjustment AdjustedNetDeposit
  , CASE WHEN bdvddp.TPCashoutsOldDef - bdvddp.TransferCoins - bdvddp.CashoutAdjustment > 0 THEN 1 ELSE 0 END Is_CO
FROM BI_DB_dbo.BI_DB_V_DDR_Daily_Panel bdvddp WITH(NOLOCK)
INNER JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON dc.RealCID=bdvddp.RealCID 
INNER JOIN DWH_dbo.Dim_Country dc1 WITH(NOLOCK) ON bdvddp.CountryID = dc1.CountryID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH(NOLOCK) ON bdvddp.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN BI_DB_dbo.BI_DB_CID_DailyCluster bdcdc WITH(NOLOCK) ON bdcdc.CID=bdvddp.RealCID AND bdcdc.IsLastCluster=1
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd WITH(NOLOCK) ON bdvddp.RealCID = bdcd.CID
LEFT JOIN (
SELECT  vl.CID
       ,vl.DateID
	   ,vl.FullDate
	   ,vl.RealizedEquity AS RealizedEquity
FROM DWH_dbo.V_Liabilities vl WITH(NOLOCK)
WHERE vl.DateID>=CAST(CONVERT(VARCHAR(8),DATEADD(MONTH,-12,GETDATE()-1), 112) AS INT) ) m ON bdvddp.RealCID=m.CID AND DATEADD(DAY, -1, CAST(bdvddp.Date AS DATE))= m.FullDate
WHERE bdvddp.DateID >=CAST(CONVERT(VARCHAR(8),DATEADD(MONTH,-12,GETDATE()-1), 112) AS INT)
  AND bdvddp.IsValidCustomer = 1
  AND bdvddp.PlayerLevelID <> 4
  AND (
  bdvddp.InternalWithdrawTPAmount > 0
  OR bdvddp.TPDepositsOldDef > 0
  OR bdvddp.TPCashoutsOldDef > 0
))c