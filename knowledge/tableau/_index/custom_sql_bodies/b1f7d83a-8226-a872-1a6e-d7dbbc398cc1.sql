SELECT 
	ddk.[Date]
	,ddk.DateID			/*	settlement date */
	,ddk.IsWeekday
	,ddk.IsWeekend
	,ddk.CalendarYear
	,bdppl.CID
	,dcy.Name [Country]
	,bdppl.InstrumentID
	,di.Name [InstrumentName]
	,di.InstrumentTypeID
	,di.InstrumentType
	,di.Exchange
	,bdppl.PositionID
	,CASE WHEN bdppl.MirrorID > 0 THEN 'Copy' ELSE 'Manual' END [IsCopy]
	,bdppl.Amount
	,bdppl.AmountInUnitsDecimal
	,bdppl.Price
	,bdppl.Amount + bdppl.PositionPnL [Equity]
	,bdppl.NOP
	,bdppl.PositionPnL
	,(bdppl.Amount + bdppl.PositionPnL)/bdppl.AmountInUnitsDecimal [InstrumentPrice]
	,bdppl.Commission
	,bdppl.IsSettled
	,fsc.RegulationID
	,bdppl.HedgeServerID
	,di.Tradable
	,di.ISINCode
	,fsc.IsValidCustomer
	,fsc.IsCreditReportValidCB
	,bdppl.UpdateDate		/* data published date */
FROM (
	SELECT 
		dd.DateKey [DateID]
		,dd.FullDate [Date]
		,dd.CalendarYear
		,dd.IsWeekday
		,dd.IsWeekend
	FROM DWH_dbo.Dim_Date dd
	) ddk
LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL bdppl ON ddk.DateID = bdppl.DateID
LEFT JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID
LEFT JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON bdppl.CID = fsc.RealCID AND fsc.RegulationID = 13
JOIN DWH_dbo.Dim_Country dcy ON fsc.CountryID = dcy.CountryID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND (bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID)