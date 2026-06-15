SELECT tot.Category
	 , tot.Metric
	 , tot.PositionType
	 , tot.Name
	 , tot.PositionTiming
	 , tot.TotalUnits
	 , tot.USDValue
	 , tot.IsValidCustomer
	 , tot.IsCreditReportValidCB
	 , tot.IsOutlier
	 , tot.OutlierTransition
	 , CASE WHEN tot.Name = 'Crypto10' THEN 'CryptoIndex' ELSE tot.CFD_Real_Filter END AS CFD_Real_Filter
	 , tot.TanganyStatus
	 , tot.IsDLTUser
	 , tot.TicketFeeVolume 
	 , IsC2P
	 , IsTransferOut
	 , Regulation
FROM 
(
SELECT 'OpeningBalance' AS Category
	 , 'OpeningBalanceCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , sum(bdidb.TotalUnits) as TotalUnits
	 , sum(bdidb.USDValue  ) as USDValue  
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
-- into #openingbalanceCFD
 FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date = <[Parameters].[Parameter 3]>
AND bdidb.Metric LIKE '%CFD%'
AND bdidb.Metric = 'OpeningBalanceCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation
,TanganyStatus
UNION all

-- drop tableif exists #closingbalanceCFD

SELECT 'ClosingBalance' AS Category
	 , 'ClosingBalanceCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , sum(bdidb.TotalUnits) as TotalUnits
	 , sum(bdidb.USDValue  ) as USDValue  
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
-- into #closingbalanceCFD
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date = <[Parameters].[Parameter 4]>
AND bdidb.Metric LIKE '%CFD%'
AND bdidb.Metric = 'ClosingBalanceCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
, IsC2P
, IsTransferOut
, Regulation

UNION all

-- drop tableif exists #txCFD

Select 'TX' AS Category
	 , 'BuyCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
, IsC2P
	 , IsTransferOut
	 , Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND bdidb.Metric = 'BuyCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	,TanganyStatus
	,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation
UNION all

-- drop tableif exists #txCFD1

Select 'TX' AS Category
	 , 'ValidZeroCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND bdidb.Metric = 'ValidZeroCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation

UNION all

-- drop tableif exists #txCFD2

Select 'TX' AS Category 
	 , 'InValidZeroCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND bdidb.Metric = 'InValidZeroCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
, IsC2P
	 , IsTransferOut
	 , Regulation

UNION all

-- drop tableif exists #txCFD3

Select 'TX' AS Category
	 , 'FullCommissionCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND bdidb.Metric = 'FullCommissionCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation

UNION all

-- drop tableif exists #txCFD4

Select 'TX' AS Category
	 , 'SellCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
	 ,	- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits,
	 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
		- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND bdidb.Metric = 'SellCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation

UNION all

-------------*************************------------------
-------------*************************------------------

-- drop tableif exists #calculatedBalanceCFD

SELECT 'Calculated_Close' AS Category
	 , 'Calculated_Closing_Balance_CFD' AS Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , SUM(a.TotalUnits) AS TotalUnits
	 , SUM(a.USDValue) AS USDValue
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
	 from 
(
		
		SELECT 'OpeningBalance' AS Category
			 , 'OpeningBalanceCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , sum(bdidb.TotalUnits) as TotalUnits
			 , sum(bdidb.USDValue  ) as USDValue  
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
,TanganyStatus
,IsDLTUser
, sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
	 , IsTransferOut
	 , Regulation
		-- into #openingbalanceCFD
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date = <[Parameters].[Parameter 3]>
		AND bdidb.Metric LIKE '%CFD%'
		AND bdidb.Metric = 'OpeningBalanceCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
,TanganyStatus
,IsDLTUser
	 , IsC2P
	 , IsTransferOut
	 , Regulation
		
		UNION all
		
	
		-- drop tableif exists #txCFD
		
		Select 'TX' AS Category
			 , 'BuyCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
			, IsTransferOut
			, Regulation
		-- into #txCFD
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'BuyCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
			, IsTransferOut
			, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD1
		
		Select 'TX' AS Category
			 , 'ValidZeroCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
			, IsTransferOut
			, Regulation		
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'ValidZeroCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
			, IsTransferOut
			, Regulation
			
		UNION all
		
		-- drop tableif exists #txCFD2
		
		Select 'TX' AS Category 
			 , 'InValidZeroCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
			, IsTransferOut
			, Regulation		
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'InValidZeroCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
			, IsTransferOut
			, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD3
		
		Select 'TX' AS Category
			 , 'FullCommissionCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
			, IsTransferOut
			, Regulation		
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'FullCommissionCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
			, IsTransferOut
			, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD4
		
		Select 'TX' AS Category
			 , 'SellCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
			 ,	- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits,
			 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
				- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
			, IsTransferOut
			, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'SellCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
			, IsTransferOut
			, Regulation
		
		) a
GROUP BY 
a.Category
	 , a.Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
	,TanganyStatus
	,IsDLTUser
		 , IsC2P
			, IsTransferOut
			, Regulation

UNION all

-- drop tableif exists #diffCFD

SELECT 'Gap' AS Category
	 , 'Gap_CFD' AS Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , sum(a.TotalUnits) as TotalUnits
	 , sum(a.USDValue  ) as USDValue
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
	,TanganyStatus
	,IsDLTUser
	, sum(TicketFeeVolume) as TicketFeeVolume
		 , IsC2P
			, IsTransferOut
			, Regulation
-- into #diffCFD
FROM 
(
-------------**** calculated close ******* ------------------

SELECT * from (
	SELECT 'Calculated_Close' AS Category
	 , 'Calculated_Closing_Balance_CFD' AS Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , SUM(a.TotalUnits) AS TotalUnits
	 , SUM(a.USDValue) AS USDValue
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
	,TanganyStatus
	,IsDLTUser
	, sum(TicketFeeVolume) as TicketFeeVolume
		 , IsC2P
		, IsTransferOut
		, Regulation
-- into #calculatedBalanceCFD
from 
(
		
		SELECT 'OpeningBalance' AS Category
			 , 'OpeningBalanceCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , sum(bdidb.TotalUnits) as TotalUnits
			 , sum(bdidb.USDValue  ) as USDValue  
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			,TanganyStatus
			,IsDLTUser
			, sum(TicketFeeVolume) as TicketFeeVolume
				 , IsC2P
		, IsTransferOut
		, Regulation
		-- into #openingbalanceCFD
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date = <[Parameters].[Parameter 3]>
		AND bdidb.Metric LIKE '%CFD%'
		AND bdidb.Metric = 'OpeningBalanceCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			,TanganyStatus
			,IsDLTUser
				 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD
		
		Select 'TX' AS Category
			 , 'BuyCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('BuyCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		-- into #txCFD
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'BuyCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD1
		
		Select 'TX' AS Category
			 , 'ValidZeroCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('ValidZeroCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		-- into #txCFD1
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'ValidZeroCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD2
		
		Select 'TX' AS Category 
			 , 'InValidZeroCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('InValidZeroCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'InValidZeroCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD3
		
		Select 'TX' AS Category
			 , 'FullCommissionCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'FullCommissionCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop tableif exists #txCFD4
		
		Select 'TX' AS Category
			 , 'SellCFD' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.TotalUnits ELSE 0 END)
			 ,	- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits,
			 --, SUM(CASE WHEN Metric IN ('BuyCFD','ValidZeroCFD','InValidZeroCFD', 'FullCommissionCFD') then bdidb.USDValue ELSE 0 END)
				- SUM(CASE WHEN Metric IN ('SellCFD') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'CFD' AS CFD_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND bdidb.Metric = 'SellCFD'
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		) a
GROUP BY 
a.Category
	 , a.Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation
		 ) obc
UNION ALL 
	SELECT obc.Category
			   , obc.Metric
			   , obc.PositionType
			   , obc.Name
			   , obc.PositionTiming
			   , -1 * obc.TotalUnits AS TotalUnits
			   , -1 * obc.USDValue AS USDValue
			   , obc.IsValidCustomer
			   , obc.IsCreditReportValidCB
			   , obc.IsOutlier
			   , obc.OutlierTransition
			   , obc.CFD_Real_Filter 
			   ,TanganyStatus
			   ,IsDLTUser
			   , 0 as TicketFeeVolume
			   	 , IsC2P
		, IsTransferOut
		, Regulation
----- ********  closing balance again ******** -----
			FROM 
	(
			SELECT 'ClosingBalance' AS Category
	 , 'ClosingBalanceCFD' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , sum(bdidb.TotalUnits) as TotalUnits
	 , sum(bdidb.USDValue  ) as USDValue  
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'CFD' AS CFD_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , 0 as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
-- into #closingbalanceCFD
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date = <[Parameters].[Parameter 4]>
AND bdidb.Metric LIKE '%CFD%'
AND bdidb.Metric = 'ClosingBalanceCFD'
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation
			) obc
) a
GROUP BY 
	   a.Category
	 , a.Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.CFD_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all 


-- drop table if exists #OpeningBalance

SELECT 'OpeningBalance' AS Category
	 , 'OpeningBalanceReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , sum(bdidb.TotalUnits) as TotalUnits
	 , sum(bdidb.USDValue  ) as USDValue  
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date = <[Parameters].[Parameter 3]>
AND bdidb.Metric LIKE '%Real%'
AND bdidb.Metric = 'OpeningBalanceReal'
-- AND bdidb.Name = @name
GROUP BY 
		bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #ClosingBalance

SELECT 'ClosingBalance' AS Category
	 , 'ClosingBalanceReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , sum(bdidb.TotalUnits) as TotalUnits
	 , sum(bdidb.USDValue  ) as USDValue  
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date = <[Parameters].[Parameter 4]>
AND bdidb.Metric LIKE '%Real%'
AND bdidb.Metric = 'ClosingBalanceReal'
-- AND bdidb.Name = @name
GROUP BY 
	   bdidb.Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation


UNION all

-- drop table if exists #txReal

Select 'TX' AS Category
	 , 'BuyReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'BuyReal')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal1

Select 'TX' AS Category
	 , 'ValidZeroReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'ValidZeroReal')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal2

Select 'TX' AS Category
	 , 'InValidZeroReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'InValidZeroReal')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal3

Select 'TX' AS Category
	 , 'FullCommissionReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'FullCommissionReal')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal4

Select 'TX' AS Category
	 , 'StakingBuy' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'StakingBuy')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal5

Select 'TX' AS Category
	 , 'RedeemBuy' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'RedeemBuy')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal6

Select 'TX' AS Category
	 , 'RedeemStakingBuy' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'RedeemStakingBuy')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal7

Select 'TX' AS Category
	 , 'SellReal' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
	 , - SUM(CASE WHEN Metric IN ('SellReal') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
	 ,	- SUM(CASE WHEN Metric IN ('SellReal') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'SellReal')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal8

Select 'TX' AS Category
	 , 'RedeemSell' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
	,	- SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		, - SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'RedeemSell')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal9

Select 'TX' AS Category
	 , 'StakingSell' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
	,	- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		,- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'StakingSell')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

-- drop table if exists #txReal10

Select 'TX' AS Category
	 , 'RedeemStakingSell' AS Metric
	 , bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
	,	- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
		AS TotalUnits
	 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
		,- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
		AS USDValue
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 , 'Real' AS Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
AND (bdidb.Metric = 'RedeemStakingSell')
-- AND bdidb.Name = @name
GROUP BY 
	  bdidb.PositionType
	 , bdidb.Name
	 , bdidb.PositionTiming
	 , bdidb.IsValidCustomer
	 , bdidb.IsCreditReportValidCB
	 , bdidb.IsOutlier
	 , bdidb.OutlierTransition
	 ,TanganyStatus
	 ,IsDLTUser
	 	 , IsC2P
		, IsTransferOut
		, Regulation

UNION all

---- ****** calculated balance ********------

-- drop table if exists #calculatedBalance

SELECT 'Calculated_Close' AS Category
	 , 'Calculated_Closing_Balance_Real' AS Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , SUM(a.TotalUnits) AS TotalUnits
	 , SUM(a.USDValue) AS USDValue
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 	 , IsC2P
		, IsTransferOut
		, Regulation
	from 
		(
			SELECT 'OpeningBalance' AS Category
			 , 'OpeningBalanceReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , sum(bdidb.TotalUnits) as TotalUnits
			 , sum(bdidb.USDValue  ) as USDValue  
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date = <[Parameters].[Parameter 3]>
		AND bdidb.Metric LIKE '%Real%'
		AND bdidb.Metric = 'OpeningBalanceReal'
		-- AND bdidb.Name = @name
		GROUP BY 
				bdidb.Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation

		UNION all
		
		-- drop table if exists #txReal
		
		Select 'TX' AS Category
			 , 'BuyReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 	 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'BuyReal')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 	 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal1
		
		Select 'TX' AS Category
			 , 'ValidZeroReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'ValidZeroReal')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal2
		
		Select 'TX' AS Category
			 , 'InValidZeroReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'InValidZeroReal')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal3
		
		Select 'TX' AS Category
			 , 'FullCommissionReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'FullCommissionReal')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal4
		
		Select 'TX' AS Category
			 , 'TX_Real' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'StakingBuy')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal5
		
		Select 'TX' AS Category
			 , 'RedeemBuy' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'RedeemBuy')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal6
		
		Select 'TX' AS Category
			 , 'RedeemStakingBuy' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
				--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'RedeemStakingBuy')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal7
		
		Select 'TX' AS Category
			 , 'SellReal' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
			 , - SUM(CASE WHEN Metric IN ('SellReal') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
			 ,	- SUM(CASE WHEN Metric IN ('SellReal') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'SellReal')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal8
		
		Select 'TX' AS Category
			 , 'RedeemSell' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
			,	- SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
				, - SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'RedeemSell')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal9
		
		Select 'TX' AS Category
			 , 'StakingSell' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
			,	- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
				,- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'StakingSell')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		
		UNION all
		
		-- drop table if exists #txReal10
		
		Select 'TX' AS Category
			 , 'RedeemStakingSell' AS Metric
			 , bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
			,	- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
				AS TotalUnits
			 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
				,- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
				AS USDValue
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 , 'Real' AS Real_Real_Filter
			 ,TanganyStatus
			 ,IsDLTUser
			 , sum(TicketFeeVolume) as TicketFeeVolume
			 , IsC2P
		, IsTransferOut
		, Regulation
		FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
		WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
		AND (bdidb.Metric = 'RedeemStakingSell')
		-- AND bdidb.Name = @name
		GROUP BY 
			  bdidb.PositionType
			 , bdidb.Name
			 , bdidb.PositionTiming
			 , bdidb.IsValidCustomer
			 , bdidb.IsCreditReportValidCB
			 , bdidb.IsOutlier
			 , bdidb.OutlierTransition
			 ,TanganyStatus
			 ,IsDLTUser
			 , IsC2P
		, IsTransferOut
		, Regulation
		) a
GROUP BY 
a.Category
	 , a. Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , IsC2P
		, IsTransferOut
		, Regulation

UNION ALL 

---- ******* gap ******** ------

-- drop table if exists #diffReal 

SELECT 'Gap' AS Category
	 , 'Gap_Real' AS Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , sum(a.TotalUnits) as TotalUnits
	 , sum(a.USDValue  ) as USDValue
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , sum(TicketFeeVolume) as TicketFeeVolume
	 , IsC2P
		, IsTransferOut
		, Regulation
FROM 
(
SELECT * from (
				SELECT 'Calculated_Close' AS Category
						 , 'Calculated_Closing_Balance_Real' AS Metric
						 , a.PositionType
						 , a.Name
						 , a.PositionTiming
						 , SUM(a.TotalUnits) AS TotalUnits
						 , SUM(a.USDValue) AS USDValue
						 , a.IsValidCustomer
						 , a.IsCreditReportValidCB
						 , a.IsOutlier
						 , a.OutlierTransition
						 , a.Real_Real_Filter
						 ,TanganyStatus
						 ,IsDLTUser
						 , sum(TicketFeeVolume) as TicketFeeVolume
						 , IsC2P
						, IsTransferOut
						, Regulation
							from 
							(
								SELECT 'OpeningBalance' AS Category
								 , 'OpeningBalanceReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , sum(bdidb.TotalUnits) as TotalUnits
								 , sum(bdidb.USDValue  ) as USDValue  
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date = <[Parameters].[Parameter 3]>
							AND bdidb.Metric LIKE '%Real%'
							AND bdidb.Metric = 'OpeningBalanceReal'
							-- AND bdidb.Name = @name
							GROUP BY 
									bdidb.Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								,TanganyStatus
								,IsDLTUser
								, IsC2P
								, IsTransferOut
								, Regulation
							UNION all
							
							-- drop table if exists #txReal
							
							Select 'TX' AS Category
								 , 'BuyReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('BuyReal') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'BuyReal')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal1
							
							Select 'TX' AS Category
								 , 'ValidZeroReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('ValidZeroReal') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'ValidZeroReal')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal2
							
							Select 'TX' AS Category
								 , 'InValidZeroReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('InValidZeroReal') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'InValidZeroReal')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal3
							
							Select 'TX' AS Category
								 , 'FullCommissionReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('FullCommissionReal') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'FullCommissionReal')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal4
							
							Select 'TX' AS Category
								 , 'TX_Real' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('StakingBuy') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'StakingBuy')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal5
							
							Select 'TX' AS Category
								 , 'RedeemBuy' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('RedeemBuy') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'RedeemBuy')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal6
							
							Select 'TX' AS Category
								 , 'RedeemStakingBuy' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 , SUM(CASE WHEN Metric IN ('RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
									--- SUM(CASE WHEN Metric IN ('SellReal','RedeemSell','StakingSell','RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'RedeemStakingBuy')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal7
							
							Select 'TX' AS Category
								 , 'SellReal' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
								 , - SUM(CASE WHEN Metric IN ('SellReal') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
								 ,	- SUM(CASE WHEN Metric IN ('SellReal') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'SellReal')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal8
							
							Select 'TX' AS Category
								 , 'RedeemSell' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
								,	- SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
									, - SUM(CASE WHEN Metric IN ('RedeemSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'RedeemSell')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal9
							
							Select 'TX' AS Category
								 , 'StakingSell' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
								,	- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
									,- SUM(CASE WHEN Metric IN ('StakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'StakingSell')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							
							UNION all
							
							-- drop table if exists #txReal10
							
							Select 'TX' AS Category
								 , 'RedeemStakingSell' AS Metric
								 , bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.TotalUnits ELSE 0 END)
								,	- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.TotalUnits ELSE 0 END)
									AS TotalUnits
								 --, SUM(CASE WHEN Metric IN ('BuyReal','ValidZeroReal','InValidZeroReal', 'FullCommissionReal', 'StakingBuy','RedeemBuy','RedeemStakingBuy') then bdidb.USDValue ELSE 0 END)
									,- SUM(CASE WHEN Metric IN ('RedeemStakingSell') then bdidb.USDValue ELSE 0 END)
									AS USDValue
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 , 'Real' AS Real_Real_Filter
								 ,TanganyStatus
								 ,IsDLTUser
								 , sum(TicketFeeVolume) as TicketFeeVolume
								 , IsC2P
								, IsTransferOut
								, Regulation
							FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
							WHERE bdidb.Date between <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
							AND (bdidb.Metric = 'RedeemStakingSell')
							-- AND bdidb.Name = @name
							GROUP BY 
								  bdidb.PositionType
								 , bdidb.Name
								 , bdidb.PositionTiming
								 , bdidb.IsValidCustomer
								 , bdidb.IsCreditReportValidCB
								 , bdidb.IsOutlier
								 , bdidb.OutlierTransition
								 ,TanganyStatus
								 ,IsDLTUser
								 , IsC2P
								, IsTransferOut
								, Regulation
							) a
					GROUP BY 
					a.Category
						 , a. Metric
						 , a.PositionType
						 , a.Name
						 , a.PositionTiming
						 , a.IsValidCustomer
						 , a.IsCreditReportValidCB
						 , a.IsOutlier
						 , a.OutlierTransition
						 , a.Real_Real_Filter
						 ,TanganyStatus
						 ,IsDLTUser
						 , IsC2P
						, IsTransferOut
						, Regulation

				) obc
UNION ALL SELECT obc.Category
			   , obc.Metric
			   , obc.PositionType
			   , obc.Name
			   , obc.PositionTiming
			   , -1 * obc.TotalUnits AS TotalUnits
			   , -1 * obc.USDValue AS USDValue
			   , obc.IsValidCustomer
			   , obc.IsCreditReportValidCB
			   , obc.IsOutlier
			   , obc.OutlierTransition
			   , obc.Real_Real_Filter 
			   ,TanganyStatus
			   ,IsDLTUser
			   , 0 as TicketFeeVolume
			   , IsC2P
				, IsTransferOut
				, Regulation
							FROM (
								SELECT 'ClosingBalance' AS Category
					 , 'ClosingBalanceReal' AS Metric
					 , bdidb.PositionType
					 , bdidb.Name
					 , bdidb.PositionTiming
					 , sum(bdidb.TotalUnits) as TotalUnits
					 , sum(bdidb.USDValue  ) as USDValue  
					 , bdidb.IsValidCustomer
					 , bdidb.IsCreditReportValidCB
					 , bdidb.IsOutlier
					 , bdidb.OutlierTransition
					 , 'Real' AS Real_Real_Filter
					 ,TanganyStatus
					 ,IsDLTUser
					 , sum(TicketFeeVolume) as TicketFeeVolume
					 , IsC2P
					, IsTransferOut
					, Regulation
					FROM BI_DB_dbo.BI_DB_IFRS15_Daily_Balance bdidb
					WHERE bdidb.Date = <[Parameters].[Parameter 4]>
					AND bdidb.Metric LIKE '%Real%'
					AND bdidb.Metric = 'ClosingBalanceReal'
					-- AND bdidb.Name = @name
					GROUP BY 
					   bdidb.Metric
					 , bdidb.PositionType
					 , bdidb.Name
					 , bdidb.PositionTiming
					 , bdidb.IsValidCustomer
					 , bdidb.IsCreditReportValidCB
					 , bdidb.IsOutlier
					 , bdidb.OutlierTransition
					 ,TanganyStatus
					 ,IsDLTUser
					 , IsC2P
					, IsTransferOut
					, Regulation
				) obc
) a
GROUP BY 
	   a.Category
	 , a.Metric
	 , a.PositionType
	 , a.Name
	 , a.PositionTiming
	 , a.IsValidCustomer
	 , a.IsCreditReportValidCB
	 , a.IsOutlier
	 , a.OutlierTransition
	 , a.Real_Real_Filter
	 ,TanganyStatus
	 ,IsDLTUser
	 , IsC2P
	, IsTransferOut
	, Regulation
) tot