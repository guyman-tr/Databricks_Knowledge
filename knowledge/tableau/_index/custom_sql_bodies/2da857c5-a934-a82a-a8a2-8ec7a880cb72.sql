SELECT 	 -- DISTINCT 
	   InstrumentName
	 , IsOpenEOD
	 , ReportDateID
	 , SnapshotDateID
	 , CONVERT(DATE, CONVERT(VARCHAR(8), ReportDateID), 112) AS ReportDate
	 , CONVERT(DATE, CONVERT(VARCHAR(8), SnapshotDateID), 112) AS SnapshotDate
	 , bdfrfcat.PositionID
	 , bdfrfcat.OriginalPositionID
	 , bdfrfcat.CID
	 , bdfrfcat.InstrumentID
	 , ActionType
	 , bdfrfcat.SettlementTime
	 , SettlementTimePrev
	 , bdfrfcat.Occurred
	 , OccurredDateID
	 , ChangeTypeID
	 , PreviousAmount
	 , AmountChanged
	 , NewAmount
	 , PreviousStopRate
	 , bdfrfcat.StopRate
	 , PreviousAmountInUnits
	 , AmountInUnits
	 , bdfrfcat.LotCountDecimal
	 , PreviousLotCountDecimal
	 , bdfrfcat.IsBuy
	 , bdfrfcat. InitForexRate
	 , bdfrfcat.EndForexRate
	 , IsStartOfDay
	 , IsEndOfDay
	 , bdfrfcat.Multiplier
	 , bdfrfcat.ProviderMarginPerLot
	 , ProviderMarginPerLotPrev
	 , bdfrfcat.eToroMarginPerLot
	 , eToroMarginPerLotPrev
	 , SettlementPrice
	 , SettlementPricePrev
	 , SettlementPriceChange
	 , ActionLotCount
	 , RunningLotCount
	 , TodayBeginLotCountRunning
	 , TodayLotCountFinal
	 , ProviderMargin
	 , TodayMarexPnL
	 , MTM
	 , PreviousProviderMargin
	 , TodayMarexPnLPlusMTM
	 , ProviderMarginChange
	 , TransferToMarex
	 , TransferToMarexRunning
	 , InvestedAmountChange
	 , InvestedAmountRunning
	 , eToroPnL
	 , ToUser
	 , ToUserRunning
	 , PositionValueAtSettlement
	 , eToroBalance
	 , bdfrfcat.UpdateDate
	 , MTMRunning
	 , TodayMarexPnLRunning
	 , TodayMarexPnLPlusMTMRunning
	 , OpenPositionsMarexPnLPlusMTM
	 , PreviousMarexPnLPlusMTMRunning
	 , MarexPnLPlusMTMRunningChange
	 , Trader
	 , bdfrfcat.HedgeServerID
			,[InitForexRateUnAdjusted]
			,[EndForexRateUnAdjusted]
			,[SettlementPriceUnAdjusted]
			,[SettlementPriceUnAdjustedPrev]
			,[SettlementPriceUnAdjustedChange]
			,[Adj]
			,[PreviousAdj]
			,[AdjChange]
			,[ClosePositionReason]
			,[IsSQF]
	 , DENSE_RANK () OVER (ORDER BY ReportDateID, SnapshotDateID, bdfrfcat.OriginalPositionID, bdfrfcat.Occurred, bdfrfcat.SettlementTime) AS MainRNForSortingTableau
	 --, CASE WHEN ActionType = 'Open' THEN 1
		--	WHEN ActionType = 'Hold' THEN 2
		--	WHEN ActionType = 'CloseOrig' THEN 4
		--ELSE 3
	 -- END AS SecondaryTableauSort
	 , dr1.Name AS Regulation
	 ,fsc.IsCreditReportValidCB
	 ,isnull(CASE WHEN di.IsFuture = 1 then bdcbcln.Amount END ,0) + isnull(CASE WHEN di.IsFuture = 1 then bdcbcln.PositionPnL END ,0)  AS EquityRealFutures
FROM BI_DB_dbo.BI_DB_Finance_Real_Futures_Custody_And_Transfers bdfrfcat
JOIN DWH_dbo.Dim_Position dp
    ON bdfrfcat.PositionID = dp.PositionID
JOIN DWH_dbo.Dim_Regulation dr1	
	ON dr1.DWHRegulationID = dp.RegulationIDOnOpen
JOIN DWH_dbo.Dim_Instrument di
	ON bdfrfcat.InstrumentID = di.InstrumentID
LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL bdcbcln
	ON dp.PositionID = bdcbcln.PositionID 
		AND bdcbcln.DateID = bdfrfcat.SnapshotDateID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc 
	ON fsc.RealCID = dp.CID
JOIN DWH_dbo.Dim_Range dr 
	on dr.DateRangeID = fsc.DateRangeID
		AND SnapshotDateID between dr.FromDateID AND dr.ToDateID
	WHERE ReportDateID BETWEEN  CAST(FORMAT(CAST(<[Parameters].[Yesterday Parameter]> AS DATE),'yyyyMMdd') as INT)  AND  CAST(FORMAT(CAST(<[Parameters].[ReportFromDate (copy)_1988339296630169610]> AS DATE),'yyyyMMdd') as INT)
	AND SnapshotDateID BETWEEN  CAST(FORMAT(CAST(<[Parameters].[ReportDateFrom (copy)_1988339296630398987]> AS DATE),'yyyyMMdd') as INT)  AND  CAST(FORMAT(CAST(<[Parameters].[SnapshotDateFrom (copy)_1988339296630476812]> AS DATE),'yyyyMMdd') as INT)