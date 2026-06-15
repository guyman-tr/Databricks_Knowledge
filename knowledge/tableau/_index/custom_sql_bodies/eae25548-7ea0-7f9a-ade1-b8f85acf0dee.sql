select      t.CID
	   ,t.YearWeekNumber
	   ,t.SSWeekNumberOfYear
	   ,t.CalendarYear
	   ,t.Seniority
	   ,t.Seniority_Seg
	   ,
	      CASE
	   WHEN t.Seniority = 0 THEN 'ThisMonth'
	   WHEN t.Seniority = 1 THEN '1_Month'
       WHEN t.Seniority = 2 THEN '2_Months'
       WHEN t.Seniority = 3 THEN '3_Months'
       WHEN t.Seniority = 4 THEN '4_Months'
       WHEN t.Seniority = 5 THEN '5_Months'
       WHEN t.Seniority = 6 THEN '6_Months'
       WHEN t.Seniority = 7 THEN '7_Months'
       WHEN t.Seniority = 8 THEN '8_Months'
       WHEN t.Seniority = 9 THEN '9_Months'
       WHEN t.Seniority = 10 THEN '10_Months'
	   WHEN t.Seniority = 11 THEN '11_Months'
	    WHEN t.Seniority >= 12 AND t.Seniority <= 23 THEN '1-2Years'
        WHEN t.Seniority >= 24 AND t.Seniority <= 35 THEN '2-3Years'
        WHEN t.Seniority >= 36 AND t.Seniority <= 47 THEN '3-4Years'
        WHEN t.Seniority >= 48 AND t.Seniority <= 59 THEN '4-5Years'
	    WHEN t.Seniority >= 60 AND t.Seniority <= 71 THEN '6-7Years'
        WHEN t.Seniority >= 72 AND t.Seniority <= 83 THEN '7-8Years'
	    WHEN t.Seniority >= 84 AND t.Seniority <= 95 THEN '8-9Years'
		WHEN t.Seniority >= 96 THEN '9+Years'
        ELSE CAST(t.Seniority AS VARCHAR) END AS Seniority_Seg2
	   ,t.IsReg_ThisD
	   ,t.IsFTD_ThisD
	   ,t.Region
	   ,t.Country
	   ,t.Channel
	   ,t.SubChannel
	   ,t.AffiliateID
	   ,t.V2_Complete
	   ,t.V3_Complete
	   ,t.IsPro
	   ,t.IsOTD
	   ,t.Weekly_Classification
	   ,t.EOW_Club
	   ,t.EOW_Regulation
	   ,dc1.MarketingRegionManualName  AS  NewMarketingRegion
	   ,t.Reg_Month
	   ,t.RegDate
	   ,t.IsReg_ThisW
	   ,t.IsFTD_ThisW
	   ,t.FTDdate
	   ,CAST(YEAR(t.FTDdate) AS VARCHAR) AS FTDYear
	   ,t.FTDA
	   ,t.FirstDayOfWeek
	   ,t.Equity
	   ,t.RealizedEquity
	   ,t.AUM
	   ,t.Credit
	   ,t.ActiveUser
	   ,t.Active
	   ,t.ActiveOpen
	   ,t.IsOpen_Copy
	   ,t.Count_Opened_Copy
	   ,t.Count_Closed_Copy
	   ,t.MoneyIn_Copy
	   ,t.MoneyOut_Copy
	   ,t.IsOpen_CopyPortfolio
	   ,t.Count_Opened_CopyPortfolio
	   ,t.Count_Closed_CopyPortfolio
	   ,t.MoneyIn_CopyPortfolio
	   ,t.MoneyOut_CopyPortfolio
	   ,t.Active_Copy
	   ,t.Active_Real_Stocks
	   ,t.Active_CFD_Stocks
	   ,t.Active_Real_Crypto
	   ,t.Active_CFD_Crypto
	   ,t.[Active_FX/Comm/Ind]
	   ,t.ActiveOpen_Copy
	   ,t.ActiveOpen_Real_Stocks
	   ,t.ActiveOpen_CFD_Stocks
	   ,t.ActiveOpen_Real_Crypto
	   ,t.ActiveOpen_CFD_Crypto
	   ,t.[ActiveOpen_FX/Comm/Ind]
	   ,t.NewTrades_Copy
	   ,t.NewTrades_Real_Stocks
	   ,t.NewTrades_CFD_Stocks
	   ,t.NewTrades_Real_Crypto
	   ,t.NewTrades_CFD_Crypto
	   ,t.[NewTrades_FX/Comm/Ind]
	   ,t.NewTrades_Total
	   ,t.AmountIn_NewTrades_Copy
	   ,t.AmountIn_NewTrades_Real_Stocks
	   ,t.AmountIn_NewTrades_CFD_Stocks
	   ,t.AmountIn_NewTrades_Real_Crypto
	   ,t.AmountIn_NewTrades_CFD_Crypto
	   ,t.[AmountIn_NewTrades_FX/Comm/Ind]
	   ,t.AmountIn_NewTrades_Total
	   ,t.Revenue_Copy
	   ,t.Revenue_Real_Stocks
	   ,t.Revenue_CFD_Stocks
	   ,t.Revenue_Real_Crypto
	   ,t.Revenue_CFD_Crypto
	   ,t.[Revenue_FX/Comm/Ind]
	   ,t.Revenue_Total
	   ,t.PnL_Copy
	   ,t.PnL_Real_Stocks
	   ,t.PnL_CFD_Stocks
	   ,t.PnL_Real_Crypto
	   ,t.PnL_CFD_Crypto
	   ,t.[PnL_FX/Comm/Ind]
	   ,t.PnL_Total
	   ,t.TotalDeposits
	   ,t.CountDeposits
	   ,t.TotalCashouts
	   ,t.TotalCoFee
	   ,t.NetDeposits
	   ,t.ACC_Revenue_Copy
	   ,t.ACC_Revenue_Real_Stocks
	   ,t.ACC_Revenue_CFD_Stocks
	   ,t.ACC_Revenue_Real_Crypto
	   ,t.ACC_Revenue_CFD_Crypto
	   ,t.[ACC_Revenue_FX/Comm/Ind]
	   ,t.ACC_Revenue_Total
	   ,t.ACC_PnL_Copy
	   ,t.ACC_PnL_Real_Stocks
	   ,t.ACC_PnL_CFD_Stocks
	   ,t.ACC_PnL_Real_Crypto
	   ,t.ACC_PnL_CFD_Crypto
	   ,t.[ACC_PnL_FX/Comm/Ind]
	   ,t.ACC_PnL_Total
	   ,t.ACC_TotalDeposits
	   ,t.ACC_CountDeposits
	   ,t.ACC_TotalCashouts
	   ,t.ACC_TotalCoFee
	   ,t.ACC_NetDeposits
	   ,t.EOW_IsFunded
	   ,t.WithdrawalToWallet
	   ,t.ACC_WithdrawalToWallet
	   ,t.LastApplicationProAccountDate
	   ,t.LastPosOpenDate
	   ,t.LastLoggedIn
	   ,t.EOW_Equity_Copy
	   ,t.EOW_Equity_Real_Crypto
	   ,t.EOW_Equity_Real_Stocks
	   ,t.EOW_Equity_CFD_Crypto
	   ,t.EOW_Equity_CFD_Stocks
	   ,t.[EOW_Equity_FX/Comm/Ind]
	   ,t.EOW_Equity_Real_Crypto_Lev1
	   ,t.EOW_Equity_Real_Stocks_LevCFD
	   ,t.EOW_Equity_CFD_Crypto_Lev1
	   ,t.EOW_Equity_CFD_Stocks_LevCFD
	   ,t.Active_Real_Stocks_Lev1
	   ,t.Active_CFD_Stocks_LevCFD
	   ,t.Active_Real_Crypto_Lev1
	   ,t.Active_CFD_Crypto_LevCFD
	   ,t.ActiveOpen_Real_Stocks_Lev1
	   ,t.ActiveOpen_CFD_Stocks_LevCFD
	   ,t.ActiveOpen_Real_Crypto_Lev1
	   ,t.ActiveOpen_CFD_Crypto_LevCFD
	   ,t.NewTrades_Real_Stocks_Lev1
	   ,t.NewTrades_CFD_Stocks_LevCFD
	   ,t.NewTrades_Real_Crypto_Lev1
	   ,t.NewTrades_CFD_Crypto_LevCFD
	   ,t.AmountIn_NewTrades_Real_Stocks_Lev1
	   ,t.AmountIn_NewTrades_CFD_Stocks_LevCFD
	   ,t.AmountIn_NewTrades_Real_Crypto_Lev1
	   ,t.AmountIn_NewTrades_CFD_Crypto_LevCFD
	   ,t.Revenue_Real_Stocks_Lev1
	   ,t.Revenue_CFD_Stocks_LevCFD
	   ,t.Revenue_Real_Crypto_Lev1
	   ,t.Revenue_CFD_Crypto_LevCFD
	   ,t.PnL_Real_Stocks_Lev1
	   ,t.PnL_CFD_Stocks_LevCFD
	   ,t.PnL_Real_Crypto_Lev1
	   ,t.PnL_CFD_Crypto_LevCFD
	   ,t.IsFunded_New
	   ,t.Active_FX
	   ,t.Active_Comm
	   ,t.Active_Ind
	   ,t.ActiveOpen_FX
	   ,t.ActiveOpen_Comm
	   ,t.ActiveOpen_Ind
	   ,t.Revenue_FX
	   ,t.Revenue_Comm
	   ,t.Revenue_Ind
	   ,t.PnL_FX
	   ,t.PnL_Comm
	   ,t.PnL_Ind
	   ,t.UpdateDate
           ,t.EOW_LSD	 
,CASE WHEN t.EOW_Club IN ('LowBronze','HighBronze') THEN 'Bronze' ELSE t.EOW_Club END AS EOW_Club_New
,LAG(t.IsFunded_New,1) OVER (PARTITION BY t.CID ORDER BY FirstDayOfWeek) AS Lag_IsEOM_Funded_NEW
,bdcd.FirstNewFundedDate
,ISNULL(bdcd.Gender,'M') Gender
,CASE WHEN t.ActiveOpen_Real_Stocks + t.ActiveOpen_CFD_Stocks > 0 THEN 1 ELSE 0 END AS ActiveOpen_Stocks
,CASE WHEN t.ActiveOpen_Real_Crypto + t.ActiveOpen_CFD_Crypto > 0 THEN 1 ELSE 0 END AS ActiveOpen_Crypto
,t.Revenue_Real_Stocks + t.Revenue_CFD_Stocks AS Revenue_Stocks
,t.Revenue_Real_Crypto + t.Revenue_CFD_Crypto AS Revenue_Crypto
,t.NewTrades_Real_Stocks + t.NewTrades_CFD_Stocks AS NewTrades_Stocks
,t.NewTrades_Real_Crypto + t.NewTrades_CFD_Crypto AS NewTrades_Crypto
,Cluster.ClusterDetail
,DATEDIFF(DAY,bdcd.FirstNewFundedDate,DATEADD(DAY,6, t.FirstDayOfWeek)) AS SeniorityFunded
,nm.CFD_Status AS Negative_Market_Status_Curr,
       CAST(CASE WHEN nm.CFD_Status = 'CFD_Blocked' THEN 'Yes' ELSE 'No' END AS CHAR) AS IsCFDBlocked_Curr,
       CASE WHEN nm.CFD_Status = 'CFD_Allowed' AND ISNULL(nm.BlockDate, '1900-01-01') > '1900-01-01' THEN 'CFD_Allowed_were_Blocked' 
       ELSE nm.CFD_Status 
       END AS Negative_Market_Status_Include_H,
       CAST(CASE 
           WHEN (nm.CFD_Status = 'CFD_Allowed' AND ISNULL(nm.BlockDate, '1900-01-01') > '1900-01-01') OR nm.CFD_Status = 'CFD_Blocked' THEN 'Blocked' 
           ELSE 'NotBlocked' 
       END AS CHAR) AS IsCFDBlocked_Include_H



,  CASE  
             WHEN bdcd.Channel LIKE '%Affiliate%' THEN 'Affiliate'
		     WHEN bdcd.Channel LIKE '%Direct%' THEN 'Direct'
			 WHEN bdcd.Channel LIKE '%Friend Referral%' THEN 'Friend Referral'
			 WHEN bdcd.Channel LIKE '%Media Performance%' THEN 'Media Performance'
		     WHEN bdcd.Channel LIKE '%Media Programmatic%' THEN 'Media Programmatic'
			 WHEN bdcd.Channel LIKE '%Mobile Acquisition%' THEN 'Mobile Acquisition'
			 WHEN bdcd.Channel LIKE '%SEM%' THEN 'SEM'
			 WHEN bdcd.Channel LIKE '%SEO%' THEN 'SEO'
		ELSE 'Other' END AS Channel_Group ,
CASE WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 34 THEN '25-34'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 44 THEN '35-44'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 45 AND 54 THEN '45-54'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) >= 55 THEN '55+'  
                  ELSE NULL END AS Age_Group


from BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData t with (nolock)
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd with (nolock)
ON t.CID = bdcd.CID 
INNER JOIN [DWH_dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON t.Country = dc1.Name
LEFT JOIN BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market nm on t.CID = nm.RealCID

LEFT JOIN (
SELECT bdcdc.CID
,bdcdc.ClusterDetail
FROM BI_DB_dbo.BI_DB_CID_DailyCluster bdcdc 
WHERE bdcdc.ToDateID = 99991231
) AS Cluster
ON t.CID = Cluster.CID
WHERE t.FirstDayOfWeek >= cast(DateAdd(wk, DateDiff(wk, -1, GetDate()) -11, -1) AS DATE)
and t.FirstDayOfWeek <= cast(DateAdd(wk, DateDiff(wk, -1, GetDate()) -1, -1) AS DATE)
--AND SSWeekNumberOfYear <>1