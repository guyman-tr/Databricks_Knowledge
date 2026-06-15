SELECT
	bdppl.InstrumentID
  , bdppl.IsBuy
  , dr1.Name AS Regulation
  , fsc.IsCreditReportValidCB
  , IsValidCustomer
  , dc.Name AS Country
  , SUM (bdppl.Amount) AS Amount
  , SUM (bdppl.PositionPnL) AS PositionPnL
  , SUM (bdppl.Amount) + SUM (bdppl.PositionPnL) AS TotalEquity
  , SUM (bdppl.AmountInUnitsDecimal) AS AmountInUnitsDecimal
  , SUM (bdppl.NOP) AS NOP
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON bdppl.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
	JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID = dc.CountryID
WHERE bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 9]> AS DATE),'yyyyMMdd') as INT)
AND bdppl.InstrumentID = 624
GROUP BY bdppl.InstrumentID, bdppl.IsBuy  , dr1.Name  , fsc.IsCreditReportValidCB, dc.Name  , IsValidCustomer