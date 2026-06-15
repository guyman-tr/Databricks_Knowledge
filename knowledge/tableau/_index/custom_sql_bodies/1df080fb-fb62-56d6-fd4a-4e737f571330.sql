SELECT bdppl.InstrumentID
	, di.Name
	, di.InstrumentDisplayName
	, di.InstrumentType
	, dr1.Name AS Regulation
	, fsc.IsCreditReportValidCB
	, fsc.IsValidCustomer
	, sum(bdppl.NOP) NOP
	, sum(CASE WHEN bdppl.IsBuy = 1 THEN bdppl.NOP ELSE -bdppl.NOP END) AS Notional
	, sum(bdppl.Amount) InvestedAmount
	, sum(bdppl.PositionPnL) PositionPnL
	, sum(bdppl.Amount) + sum(bdppl.PositionPnL) AS Equity
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN DWH_dbo.Dim_Instrument di
	ON bdppl.InstrumentID = di.InstrumentID AND di.IsFuture = 1 AND di.InstrumentTypeID IN (10,5,6) AND bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON bdppl.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
	ON dr1.DWHRegulationID = fsc.RegulationID
WHERE bdppl.Occurred < = '20250801'
GROUP BY 
bdppl.InstrumentID
	, di.Name
	, di.InstrumentDisplayName
	, di.InstrumentType
	, dr1.Name 
	, fsc.IsCreditReportValidCB
	, fsc.IsValidCustomer