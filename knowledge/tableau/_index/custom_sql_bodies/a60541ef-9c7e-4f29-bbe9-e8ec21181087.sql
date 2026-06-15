SELECT 
    bdppl.DateID,
    bdppl.CID,  
    bdppl.InstrumentID,
    di.Name AS InstrumentName,
    di.InstrumentDisplayName,
    di.IsFuture,
    dr1.Name AS Regulation,
	fsc.IsCreditReportValidCB,
    SUM(bdppl.Amount) AS Amount,
    SUM(bdppl.PositionPnL) AS PositionPnL,
    SUM(bdppl.Amount) + SUM(bdppl.PositionPnL) AS Equity
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN DWH_dbo.Dim_Instrument di
    ON bdppl.InstrumentID = di.InstrumentID 
    AND di.IsFuture = 1
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON bdppl.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
WHERE bdppl.DateID =  CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
GROUP BY    dr1.Name,   di.InstrumentDisplayName,  bdppl.CID,  bdppl.DateID, bdppl.InstrumentID, di.Name, di.IsFuture,fsc.IsCreditReportValidCB
HAVING 
    (<[Parameters].[Parameter 2]> = 'Positive' AND SUM(bdppl.Amount) + SUM(bdppl.PositionPnL) > 0) 
    OR 
    (<[Parameters].[Parameter 2]> = 'Negative' AND SUM(bdppl.Amount) + SUM(bdppl.PositionPnL) < 0)