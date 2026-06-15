SELECT <[Parameters].[Parameter 1]> AS DateID, a.*, CASE WHEN NOP < 0 THEN -NOP ELSE NOP END AS QSR_Notional
FROM 
(
SELECT bdppl.InstrumentID, di.InstrumentType, di.Name, dr1.Name AS Regulation, fsc.IsCreditReportValidCB
, SUM(CASE WHEN bdppl.IsBuy = 1 THEN NOP ELSE 0 END) AS Total_Long_OP
, SUM(CASE WHEN bdppl.IsBuy = 0 THEN NOP ELSE 0 END) AS Total_Short_OP
, SUM(bdppl.NOP) AS NOP, SUM(CASE WHEN bdppl.IsBuy = 1 THEN NOP ELSE -NOP END) AS GrossNotional
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN DWH_dbo.Dim_Instrument di
ON bdppl.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
ON bdppl.CID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID AND <[Parameters].[Parameter 1]> BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
ON dr1.DWHRegulationID = fsc.RegulationID
WHERE bdppl.DateID = <[Parameters].[Parameter 1]>
AND bdppl.IsSettled = 0
GROUP BY bdppl.InstrumentID, di.InstrumentType, di.Name, dr1.Name, fsc.IsCreditReportValidCB
) a