--- CFD balance

SELECT tot.ExcelOrder
	 , tot.Metric
	 , tot.PositionType
	 , tot.Date
	 , tot.YearMonth
	 , tot.Name
	 , tot.PositionTiming
	 , tot.TotalUnits
	 , tot.USDValue
	 , tot.IsValidCustomer
	 , tot.IsCreditReportValidCB
	 , tot.IsOutlier
	 , tot.OutlierTransition
	 , CASE WHEN tot.Name = 'Crypto10' THEN 'CryptoIndex' ELSE tot.CFD_Real_Filter END AS CFD_Real_Filter
	 , tot.IsDLTUser
	 , tot.TanganyStatus
	 , tot.TicketFeeVolume 
FROM 
(
SELECT bdidb.ExcelOrder
	 , bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.TotalUnits
	 , bdidb.USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
		, bdidb.TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND bdidb.Metric LIKE '%CFD%'
-- ORDER BY bdidb.ExcelOrder

UNION ALL 

SELECT 30 as ExcelOrder
	 , 'Calc_Closing_Balance_CFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TicketFeeVolume ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD') then  bdidb.TicketFeeVolume ELSE 0 END)
		AS  TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date BETWEEN  DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND bdidb.Metric LIKE '%CFD%'
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,bdidb.IsDLTUser
        , TanganyStatus

UNION ALL 

SELECT 31 as ExcelOrder
	 , 'Diff_Calc_From_Data' AS Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD', 'ClosingBalanceCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD', 'ClosingBalanceCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceCFD','BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TicketFeeVolume ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD', 'ClosingBalanceCFD') then bdidb.TicketFeeVolume ELSE 0 END)
		AS TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between  DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND bdidb.Metric LIKE '%CFD%'
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,bdidb.IsDLTUser
        , TanganyStatus


UNION all

SELECT bdidb.ExcelOrder
	 , bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.TotalUnits
	 , bdidb.USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
		, bdidb.TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between  DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND (bdidb.Metric LIKE '%Real%' OR bdidb.Metric LIKE '%Redeem%' OR bdidb.Metric LIKE '%Staking%' OR bdidb.Metric IN ('OutOfDLTStatusClosingBalance','IntoDLTStatusOpeningBalance'))
-- ORDER BY bdidb.ExcelOrder

UNION ALL 

SELECT 30 as ExcelOrder
	 , 'Calc_Closing_Balance_Real' AS Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TicketFeeVolume ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TicketFeeVolume ELSE 0 END)
		AS TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between  DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND (bdidb.Metric LIKE '%Real%' OR bdidb.Metric LIKE '%Redeem%' OR bdidb.Metric LIKE '%Staking%')
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,bdidb.IsDLTUser
        , TanganyStatus

UNION ALL 


SELECT 31 as ExcelOrder
	 , 'Diff_Calc_From_Data' AS Metric
	 , bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell','ClosingBalanceReal') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell','ClosingBalanceReal') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS CFD_Real_Filter
	 ,bdidb.IsDLTUser
        , TanganyStatus
	 , SUM(CASE WHEN Metric IN ('OpeningBalanceReal','BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TicketFeeVolume ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell','ClosingBalanceReal') then bdidb.TicketFeeVolume ELSE 0 END)
		AS TicketFeeVolume
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between  DATEADD(DAY, 1, EOMONTH(GETDATE(), -2)) and EOMONTH(GETDATE(), -1) 
AND (bdidb.Metric LIKE '%Real%' OR bdidb.Metric LIKE '%Redeem%' OR bdidb.Metric LIKE '%Staking%')
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Date
	 , bdidb.YearMonth
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,bdidb.IsDLTUser
        , TanganyStatus
) tot