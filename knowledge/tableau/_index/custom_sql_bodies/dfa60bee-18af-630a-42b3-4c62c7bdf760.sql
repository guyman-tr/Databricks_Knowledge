SELECT el.*
	, di.Symbol
	, dr1.Name AS Regulation
	, dc.Name AS Country
, IsCreditReportValidCB
FROM BI_DB_dbo.BI_DB_V_StockMargin_EventLog el 
join DWH_dbo.Dim_Instrument di 
on el.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON el.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND el.OccurredDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
JOIN DWH_dbo.Dim_Country dc
	ON fsc.CountryID = dc.CountryID